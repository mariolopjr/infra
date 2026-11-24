#!/usr/bin/env bash
# infra-install [host]. installer.nix sets INFRA_SELF (this flake), INFRA_SUBSTITUTERS,
# INFRA_KEYS and INFRA_CLONE_URLS (space-separated) and the PATH.
set -euo pipefail

flake=${INFRA_FLAKE:-$INFRA_SELF}
# The stock NixOS ISO lacks these caches
export NIX_CONFIG="experimental-features = nix-command flakes
extra-substituters = $INFRA_SUBSTITUTERS
extra-trusted-public-keys = $INFRA_KEYS${NIX_CONFIG:+
$NIX_CONFIG}"
# Hosts for this machine's arch. A name finds its -<arch> variant (winterfell-vm ->
# winterfell-vm-x86_64)
# shellcheck disable=SC2016 # ${n} is Nix
list=$(nix eval --impure --raw "$flake#nixosConfigurations" --apply 'c: toString (builtins.filter (n:
  builtins.match "installer-.*" n == null && c.${n}.config.nixpkgs.hostPlatform.system == builtins.currentSystem
) (builtins.attrNames c))')
read -ra hosts <<<"$list"
host=
if (($# == 1)); then
  for h in "$1" "$1-$(uname -m)"; do
    [[ " ${hosts[*]} " == *" $h "* ]] && host=$h && break
  done
elif (($# == 0 && ${#hosts[@]} == 1)); then
  host=${hosts[0]}
elif (($# == 0 && ${#hosts[@]} > 1)); then
  PS3="Host to install: "
  select host in "${hosts[@]}"; do
    [[ -n $host ]] && break
  done
fi
if [[ -z $host ]]; then
  echo "usage: infra-install [host]" >&2
  echo "hosts for $(uname -m): ${hosts[*]:-none}" >&2
  exit 2
fi
echo "Installing $host" >&2
[[ $EUID -eq 0 ]] || exec sudo -E "$0" "$host"

# Command substitution, not <(...), so a failed eval (offline, typo'd host) exits here.
list=$(nix eval --raw "$flake#nixosConfigurations.$host.config.disko.devices.disk" \
  --apply 'd: builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (n: v: n + " " + v.device) d))')
mapfile -t disks <<<"$list"
missing=0
for entry in "${disks[@]}"; do
  dev=${entry#* }
  [[ -e $dev ]] || {
    echo "missing disk: $dev" >&2
    missing=1
  }
done
if ((missing)); then
  echo "Available disks:" >&2
  find /dev/disk/by-id -mindepth 1 -maxdepth 1 ! -name '*-part*' -printf '  %p -> %l\n' | sort >&2
  echo "Set den.hosts.*.$host.disks in its modules/hosts/ file, then retry (INFRA_FLAKE=<checkout>)." >&2
  exit 1
fi

umount -R /mnt 2>/dev/null || true
swapoff -a

# Per disk: wipe (typed confirmation) or keep. Disko's format step skips every
# layer that already exists, so kept unwiped are only unlocked and mounted.
wipe=() keep=()
for entry in "${disks[@]}"; do
  read -r name dev <<<"$entry"
  lsblk -dno SIZE,MODEL "$dev" | sed "s|^|$name: $dev  |"
  read -rp "Format $name? [y/N] " ans
  if [[ $ans =~ ^[Yy](es)?$ ]]; then
    read -rp "This erases $dev. Type '$name' to confirm: " ans
    [[ $ans == "$name" ]] || {
      echo "not confirmed, aborting" >&2
      exit 1
    }
    wipe+=("$dev")
  else
    luks=$(lsblk -nrpo NAME,FSTYPE "$dev" | awk '$2=="crypto_LUKS"{print $1}')
    [[ -n $luks ]] || {
      echo "$name has no LUKS volume to keep; answer y to format it" >&2
      exit 1
    }
    keep+=("$luks")
  fi
done

# One passphrase for all disks: checked against unwiped disks, reused for new ones.
# disks.nix names this path as disko's passwordFile.
key=/tmp/luks.key
trap 'rm -f "$key"' EXIT
ok=0
for _ in 1 2 3; do
  read -rsp "LUKS passphrase: " p1
  echo
  if ((${#keep[@]} == 0)); then
    read -rsp "Again: " p2
    echo
    [[ $p1 == "$p2" && -n $p1 ]] || {
      echo "passphrases differ or are empty" >&2
      continue
    }
  fi
  # Subshell: a global umask 077 would also make disko's mountpoints and subvolumes 700.
  (
    umask 077
    printf '%s' "$p1" >"$key"
  )
  ok=1
  for luks in "${keep[@]}"; do
    cryptsetup open --test-passphrase --key-file "$key" "$luks" || {
      echo "wrong passphrase for $luks" >&2
      ok=0
      break
    }
  done
  ((ok)) && break
done
((ok)) || exit 1

for dev in "${wipe[@]}"; do
  # Close and erase signatures in partitions first
  lsblk -nrpo NAME,TYPE "$dev" | awk '$2=="crypt"{print $1}' | xargs -r -n1 cryptsetup close
  lsblk -nrpo NAME,TYPE "$dev" | awk '$2=="part"{print $1}' | xargs -r wipefs -af
  sgdisk --zap-all "$dev"
  wipefs -af "$dev"
  partprobe "$dev" || true
done

if ((${#wipe[@]})); then mode=format,mount; else mode=mount; fi
disko --mode "$mode" --flake "$flake#$host"
# Root is tmpfs, so the hash on /persist is the password (hashedPasswordFile).
pw=/mnt/persist/passwords/mario
if [[ -s $pw ]]; then
  echo "Kept existing password for mario"
else
  install -d -m 700 "$(dirname "$pw")"
  while :; do
    read -rsp "Password for mario: " p1
    echo
    read -rsp "Again: " p2
    echo
    [[ $p1 == "$p2" && -n $p1 ]] && break
    echo "passwords differ or are empty" >&2
  done
  (
    umask 077
    mkpasswd -m yescrypt -s <<<"$p1" >"$pw"
  )
fi

nixos-install --flake "$flake#$host" --no-root-passwd --no-channel-copy

# Public infra repo
dest=/mnt/persist/home/mario/.config/infra # /home is tmpfs
mkdir -p "$(dirname "$dest")"
if git -C "$dest" rev-parse -q --verify HEAD >/dev/null 2>&1; then
  echo "Kept existing ~/.config/infra checkout"
else
  [[ -e $dest ]] && mv "$dest" "$dest.before-install.$(date +%s)"
  # Unpushed commits install: a checkout passed as INFRA_FLAKE, or in the e2e VM the
  # host's checkout (`just vm-cache`)
  read -ra srcs <<<"$INFRA_CLONE_URLS"
  [[ -d $flake/.git ]] && srcs=("$flake" "${srcs[@]}")
  cloned=0
  for src in "${srcs[@]}"; do
    GIT_TERMINAL_PROMPT=0 git -c safe.directory='*' clone -q "$src" "$dest" && {
      cloned=1
      break
    }
  done
  if ((cloned)); then
    git -C "$dest" remote set-url origin https://github.com/mariolopjr/infra.git
    git -C "$dest" remote set-url --push origin git@github.com:mariolopjr/infra.git
  else
    cp -rL "$flake/." "$dest"
    chmod -R u+w "$dest"
    echo "Clone failed; copied the ISO's flake to ~/.config/infra instead." >&2
  fi
fi
nixos-enter --root /mnt -c 'chown -R mario:users /persist/home/mario'

echo "Done. Reboot and remove the installer."
