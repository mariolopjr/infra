#!/usr/bin/env bash
# activate-plugins <managed.json> <stamp>: install the plugins the managed settings enable,
# then write the managed path to <stamp> so activation skips it until the settings change.
set -euo pipefail

managed=$1
wanted=$(jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' "$managed")
[ -n "$wanted" ] || exit 0

# install resolves plugin@marketplace only against marketplaces already checked out.
# add fails for one already added, so its status is ignored.
jq -r '.extraKnownMarketplaces | to_entries[] | .value.source
  | select(.source == "github" or .source == "directory") | .repo // .path' "$managed" |
	while IFS= read -r src; do
		[ -z "$src" ] || claude plugin marketplace add "$src" >/dev/null 2>&1 || true
	done
claude plugin marketplace update >/dev/null 2>&1 || true

installed=$HOME/.claude/plugins/installed_plugins.json
ok=0
while IFS= read -r plugin; do
	if [ -f "$installed" ] && jq -e --arg p "$plugin" '.plugins | has($p)' "$installed" >/dev/null; then
		continue
	fi
	echo "claude: installing plugin $plugin"
	# -y: activation has no TTY, which install requires for url-sourced plugins
	claude plugin install "$plugin" --scope user -y || ok=1
done <<<"$wanted"
[ $ok = 0 ] || exit 1
mkdir -p "$(dirname "$2")"
echo "$managed" >"$2"
