#!/usr/bin/env bash
# activate-settings <managed.json>: merge the managed top-level keys into
# ~/.claude/settings.json, keeping every other key Claude wrote.
set -euo pipefail

f=$HOME/.claude/settings.json
mkdir -p "$(dirname "$f")"
[ -s "$f" ] || echo '{}' >"$f"
jq --slurpfile m "$1" '. + $m[0]' "$f" >"$f.tmp"
mv "$f.tmp" "$f"
