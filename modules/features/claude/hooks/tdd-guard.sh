#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit|NotebookEdit|Bash) hook.
#
# /implement writes <git-dir>/tdd-phase per worktree. Line 1 is the phase:
#   green   lines 2+ are repo-relative test files from the red commit, frozen
#   frozen  every test file is frozen (refactor, perf, chore)
# No marker, no repo: allow.
#
# A Rust source file (not under tests/, not tests.rs) freezes only its inline test region
# (see test-region): Edit, MultiEdit and Write are applied to the current text and denied
# only when that region changes. Bash that mutates such a file is denied whole.
#
# Bash: a command segment (split on ; && || |) that removes, moves or edits a
# frozen file in place (rm, mv, cp, tee, truncate, git rm/mv, sed/perl -i) or
# redirects onto one is denied. Reads and git checkout/restore stay allowed.
# Anything subtler still reaches /review-gauntlet §8, which diffs.
#
# Fails open on every error.
set -u

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || exit 0
if [ "$tool" = Bash ]; then
	cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || exit 0
	[ -n "$cmd" ] || exit 0
	dir=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
	# Agents prefix every call with `cd <worktree> &&`
	if [[ $cmd =~ ^[[:space:]]*cd[[:space:]]+([^[:space:];&|]+) ]]; then
		dir=${BASH_REMATCH[1]//[\"\']/}
		dir=${dir/#\~/$HOME}
	fi
	[ -d "$dir" ] || exit 0
	dir=$(cd "$dir" && pwd -P)
else
	file_path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input" 2>/dev/null) || exit 0
	[ -n "$file_path" ] || exit 0
	# The file, or its directory, may not exist yet. Walk up to one that does.
	dir=$(dirname "$file_path")
	while [ ! -d "$dir" ] && [ "$dir" != / ]; do dir=$(dirname "$dir"); done
	# pwd -P: macOS /var is /private/var, and git reports the resolved toplevel.
	real=$(cd "$dir" 2>/dev/null && pwd -P)${file_path#"$dir"} || exit 0
	dir=$(cd "$dir" && pwd -P)
fi

here=$(cd "$(dirname "$0")" && pwd)
region_cmd=$here/test-region
region() { bash "$region_cmd" "$@" 2>/dev/null; }

git_dir=$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
mark="$git_dir/tdd-phase"
[ -f "$mark" ] || exit 0
top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
phase=$(head -n 1 "$mark")

is_test() {
	case $1 in
	*_test.go) return 0 ;;
	test_*.py | */test_*.py | *_test.py) return 0 ;;
	*.test.* | *.spec.*) return 0 ;;
	tests/*.rs | */tests/*.rs | tests.rs | */tests.rs) return 0 ;;
	*Tests.cs | *Test.cs) return 0 ;;
	esac
	return 1
}

# is_inline <repo-relative path>: Rust source whose tests, if any, live inline
is_inline() {
	case $1 in *.rs) ! is_test "$1" ;; *) return 1 ;; esac
}

# is_frozen <repo-relative path>
is_frozen() {
	case $phase in
	green) tail -n +2 "$mark" | grep -qxF -- "$1" ;;
	frozen) is_test "$1" || { is_inline "$1" && [ -n "$(region "$top/$1")" ]; } ;;
	*) return 1 ;;
	esac
}

# slurp <jq filter>: a string field verbatim, trailing newlines kept
slurp() {
	local v
	v=$(
		jq -j "$1" <<<"$input"
		printf x
	)
	printf '%s' "${v%x}"
}

# after_edit: the file's text once this Edit, MultiEdit or Write is applied
after_edit() {
	local text old new i n
	if [ "$tool" = Write ]; then
		slurp '.tool_input.content // ""'
		return
	fi
	text=$(
		cat "$real"
		printf x
	)
	text=${text%x}
	if [ "$tool" = Edit ]; then
		n=1
	else
		n=$(jq '.tool_input.edits | length' <<<"$input")
	fi
	for ((i = 0; i < n; i++)); do
		local e=.tool_input
		[ "$tool" = Edit ] || e=".tool_input.edits[$i]"
		old=$(slurp "$e.old_string // \"\"")
		new=$(slurp "$e.new_string // \"\"")
		[ -n "$old" ] || continue
		if [ "$(jq -r "$e.replace_all // false" <<<"$input")" = true ]; then
			text=${text//"$old"/"$new"}
		else
			text=${text/"$old"/"$new"}
		fi
	done
	printf '%s' "$text"
}

# rel_of <word>: the repo-relative path a command word names, empty if outside the repo
rel_of() {
	local w=${1//[\"\']/}
	case $w in
	/*) ;;
	*) w="$dir/$w" ;;
	esac
	# Resolve symlinked parents (macOS /var) to match the toplevel git reports
	[ -d "${w%/*}" ] && w="$(cd "${w%/*}" && pwd -P)/${w##*/}"
	case $w in "$top"/*) printf '%s' "${w#"$top"/}" ;; esac
}

deny() {
	local what="$1 is"
	is_inline "$1" && what="the test module (#[cfg(test)] mod tests) in $1 is"
	jq -nc --arg reason "TDD: $what frozen in phase '$phase'. Its tests are the spec. New tests may be appended to it and the code above it stays editable, with Edit or Write; Bash edits to the file are denied. If one is wrong, stop and report it with the Definition-of-done box it contradicts; do not edit, move or delete it." \
		'{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
	exit 0
}

if [ "$tool" != Bash ]; then
	case $real in "$top"/*) ;; *) exit 0 ;; esac
	rel=${real#"$top"/}
	is_frozen "$rel" || exit 0
	if is_inline "$rel" && [ -f "$real" ] && [ "$tool" != NotebookEdit ]; then
		# Tests may be appended inside the module: no line removed or changed, and no
		# added line at column 0, which would be a new item after the module
		diff <(region "$real") <(after_edit | region -) | grep -qE '^<|^> [^[:space:]]' && deny "$rel"
		exit 0
	fi
	deny "$rel"
fi

mutating='^(sudo[[:space:]]+)?(rm|mv|cp|tee|truncate|unlink|git[[:space:]]+(rm|mv))([[:space:]]|$)|^(sed|perl|ruby)[[:space:]](.*[[:space:]])?-[a-zA-Z]*i'
while IFS= read -r seg; do
	seg=${seg#"${seg%%[![:space:]]*}"}
	if [[ $seg =~ $mutating ]]; then
		read -ra words <<<"$seg"
		for w in "${words[@]:1}"; do
			rel=$(rel_of "${w#>}")
			[ -n "$rel" ] && is_frozen "$rel" && deny "$rel"
		done
	fi
	if [[ $seg =~ \>\>?[[:space:]]*([^[:space:]]+) ]]; then
		rel=$(rel_of "${BASH_REMATCH[1]}")
		[ -n "$rel" ] && is_frozen "$rel" && deny "$rel"
	fi
done < <(printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g')
exit 0
