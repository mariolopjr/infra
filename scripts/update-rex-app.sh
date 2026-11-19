#!/usr/bin/env bash
# Pin Rex.app to the newest DMG in its Sparkle appcast. The DMG has no stable channel URL,
# so a flake input can't follow it.
set -euo pipefail
feed=${1:-https://blob.superlogical.com/public/rex-app/preview-arm64/appcast.xml}
out=${2:-modules/features/rex/app.json}

url=$(curl -fsSL "$feed" | grep -o 'enclosure url="[^"]*"' | cut -d'"' -f2 | sort -V | tail -1)
[ -n "$url" ] || { echo "no enclosure in $feed" >&2; exit 1; }
[ "$url" = "$(jq -r .url "$out" 2>/dev/null)" ] && exit 0

version=${url##*/Rex-}
hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
jq -n --arg url "$url" --arg version "${version%.dmg}" --arg hash "$hash" '{$version, $url, $hash}' > "$out"
