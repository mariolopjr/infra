#!/usr/bin/env bash
# vm-cache [dir]: serve this machine's store (harmonia) and this repo (git daemon) to the e2e VM
# (VM accesses 10.0.2.2:5080), after building winterfell-vm-<arch> so its closure is there. Out-links
# are GC roots.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
dir=${1:-$HOME/.cache/infra-vm-cache}
arch=$(uname -m)
build=$repo#nixosConfigurations.winterfell-vm-${arch/arm64/aarch64}.config.system.build

mkdir -p "$dir"
nix build --out-link "$dir/system" "$build.toplevel"
nix build --out-link "$dir/disko" "$build.formatMount"
nix flake archive "$repo"
printf 'bind = "127.0.0.1:5080"\npriority = 10\n' >"$dir/harmonia.toml"
# git://10.0.2.2/infra for the installer: this checkout's commits, read-only, loopback only
git daemon --listen=127.0.0.1 --reuseaddr --export-all --base-path="$(dirname "$repo")" "$repo" &
trap 'kill $!' EXIT
CONFIG_FILE="$dir/harmonia.toml" nix run nixpkgs#harmonia
