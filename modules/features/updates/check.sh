# Builds main's system for this host (the "download") and diffs it against the running one.
state=${XDG_CACHE_HOME:-$HOME/.cache}/infra-update
mkdir -p "$state"

rev=$(git ls-remote https://github.com/mariolopjr/infra refs/heads/main | cut -f1)
[[ -n $rev ]]
if [[ $rev != "$(cat "$state/rev" 2>/dev/null)" || ! -e $state/system ]]; then
  nix build --out-link "$state/system" \
    "github:mariolopjr/infra/$rev#nixosConfigurations.$(</proc/sys/kernel/hostname).config.system.build.toplevel"
  echo "$rev" >"$state/rev"
fi

nvd diff /run/current-system "$state/system" >"$state/diff"
grep -c '^\[' "$state/diff" >"$state/count.tmp" || true
mv "$state/count.tmp" "$state/count"
