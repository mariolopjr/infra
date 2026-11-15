#!/usr/bin/env bash
# PreToolUse(Write) hook.
#
# Claude Code loads .claude/rules/*.md carrying `paths:` frontmatter when it
# READS a matching file. A file written from scratch is never read, so its rule
# is absent for exactly the write that most needs it. This denies that first
# write, hands the rule back as context, and lets the retry apply it.
#
# Fires at most once per rule per session. Fails open on every error.
set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$file_path" ] || exit 0

# Existing file means Claude had to Read it first, so native loading already ran.
[ -e "$file_path" ] && exit 0

session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
state_dir="${TMPDIR:-/tmp}/claude-rules/${session_id//[^A-Za-z0-9_-]/_}"

base=${file_path##*/}
matched=()

for root in "$HOME/.claude/rules" "${CLAUDE_PROJECT_DIR:-}/.claude/rules"; do
	[ -n "$root" ] && [ -d "$root" ] || continue
	while IFS= read -r rule; do
		globs=$(awk '
			NR == 1 && $0 != "---" { exit }
			NR > 1 && $0 == "---" { exit }
			/^paths:[[:space:]]*$/ { p = 1; next }
			p && /^[[:space:]]*-[[:space:]]/ {
				v = $0
				sub(/^[[:space:]]*-[[:space:]]*/, "", v)
				print v
				next
			}
			p && /^[^[:space:]]/ { p = 0 }
		' "$rule" 2>/dev/null)
		[ -n "$globs" ] || continue

		while IFS= read -r g; do
			g=${g%"${g##*[![:space:]]}"}
			g=${g%\"} g=${g#\"}
			g=${g%\'} g=${g#\'}
			[ -n "$g" ] || continue
			# Unquoted on purpose: $g is the glob, and [[ ]] lets * cross '/'.
			# shellcheck disable=SC2053
			if [[ $file_path == $g || $base == $g ]]; then
				matched+=("$rule")
				break
			fi
		done <<<"$globs"
	done < <(find -L "$root" -type f -name '*.md' 2>/dev/null)
done

[ ${#matched[@]} -gt 0 ] || exit 0
mkdir -p "$state_dir" 2>/dev/null || exit 0

payload=""
names=""
for rule in "${matched[@]}"; do
	key=$(printf '%s' "$rule" | shasum 2>/dev/null | cut -d' ' -f1)
	[ -n "$key" ] || continue
	[ -e "$state_dir/$key" ] && continue
	: >"$state_dir/$key"

	body=$(awk '
		NR == 1 && $0 == "---" { f = 1; next }
		f && $0 == "---" { f = 0; next }
		!f
	' "$rule" 2>/dev/null)
	[ -n "$body" ] || continue

	payload="${payload}<project-rule source=\"${rule}\">
${body}
</project-rule>
"
	names="${names}${names:+, }${rule##*/}"
done

[ -n "$payload" ] || exit 0

jq -nc \
	--arg ctx "$payload" \
	--arg reason "Rule not yet in context for a file you are creating: ${names}. It has now been loaded. Re-issue the write applying it." \
	'{
		hookSpecificOutput: {
			hookEventName: "PreToolUse",
			permissionDecision: "deny",
			permissionDecisionReason: $reason,
			additionalContext: $ctx
		}
	}'
