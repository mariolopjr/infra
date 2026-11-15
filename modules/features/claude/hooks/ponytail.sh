#!/usr/bin/env bash
# Emits the ponytail ruleset as hook context
# Source file is fetched by claude.nix (pinned ponytail release).
#
# Usage: ponytail.sh            # SessionStart
#        ponytail.sh --subagent # SubagentStart, gated by PONYTAIL_SUBAGENT_MATCHER
set -uo pipefail

MODE="${PONYTAIL_DEFAULT_MODE:-full}"
[ "$MODE" = "off" ] && exit 0

SKILL="$HOME/.claude/ponytail/skills/ponytail/SKILL.md"
[ -r "$SKILL" ] || exit 0

if [ "${1:-}" = "--subagent" ]; then
  # Upstream reads agent_type from stdin and fails OPEN on missing/unparseable
  # input or a bad regex, so scoping never silently drops the persona.
  agent=$(jq -r '.agent_type // empty' 2>/dev/null) || agent=""
  if [ -n "$agent" ] && [ -n "${PONYTAIL_SUBAGENT_MATCHER:-}" ]; then
    # jq's Oniguruma handles the negative lookahead; grep -E cannot, and BSD
    # grep has no -P. try/catch keeps a bad regex failing open.
    match=$(jq -rn --arg a "$agent" --arg re "$PONYTAIL_SUBAGENT_MATCHER" \
      'try ($a | test($re; "i")) catch true' 2>/dev/null)
    [ "$match" = "false" ] && exit 0
  fi
fi

printf 'PONYTAIL MODE ACTIVE — level: %s\n\n' "$MODE"

# Strip frontmatter, then drop intensity-table rows and worked examples for
# every mode but the active one. Mirrors filterSkillBodyForMode() upstream.
OTHERS=$(printf '%s\n' lite full ultra | grep -vx "$MODE" | paste -sd'|' -)

awk 'NR==1 && $0=="---" {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$SKILL" \
  | grep -vE "^\|[[:space:]]*\*\*($OTHERS)\*\*[[:space:]]*\|" \
  | grep -vE "^-[[:space:]]*($OTHERS):[[:space:]]*\""
