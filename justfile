[private]
default:
    @just --list

# Apply the config to this machine
rebuild:
    {{ if os() == "macos" { "sudo -H darwin-rebuild switch --flake ." } else { "sudo nixos-rebuild switch --flake ." } }}

# Evaluate every host, ISO and package for all systems
check:
    @mkdir -p .devenv && printf %s "$PWD" > .devenv/root
    nix flake check --no-build --all-systems --override-input devenv-root "file+file://$PWD/.devenv/root"

fmt:
    nix fmt

# Shellcheck every shell script
lint:
    git ls-files -co --exclude-standard '*.sh' modules/features/claude/hooks/test-region | xargs shellcheck

# Run the infra-install host choice test
test-install:
    bash modules/infra-install.test.sh

# Update all inputs or only the named ones
update *inputs:
    nix flake update {{ inputs }}
    {{ if inputs == "" { "scripts/update-rex-app.sh" } else { "" } }}

# Build the installer ISO (aarch64 or x86_64)
iso arch="x86_64":
    nix build .#packages.{{ arch }}-linux.iso
    ls result/iso

# List files on the tmpfs root that may need an entry in preservation.nix
ephemeral:
    scripts/ephemeral.sh

# Run the e2e VM: install (boot ISO), boot (installed disks), or reset (delete disks)
vm mode="install":
    nix run .#e2e -- {{ mode }}

# Serve this machine's store and this repo to the e2e VM
vm-cache *dir:
    scripts/vm-cache.sh {{ dir }}

# SSH into the running e2e VM
vm-ssh:
    ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mario@localhost

# Headless check that the Neovim config wires up its plugins and keymaps
test-nvim:
    #!/usr/bin/env bash
    set -euo pipefail
    cfg=$(mktemp -d); trap 'rm -rf "$cfg"' EXIT
    ln -s "$PWD/modules/features/neovim/nvim" "$cfg/nvim"
    for env in SSH_TTY=/dev/pts/0 REX_BLOCK=1; do
        env -u SSH_TTY -u REX_BLOCK "$env" XDG_CONFIG_HOME=$cfg nvim --headless -u "$cfg/nvim/init.lua" -l modules/features/neovim/tests/config_test.lua
    done
