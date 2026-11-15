# infra

Nix flake for all my systems, built with [flake-parts](https://github.com/hercules-ci/flake-parts), [import-tree](https://github.com/vic/import-tree) and [den](https://github.com/denful/den). Every file under `modules/` is loaded automatically.

## Hosts

| Host | Machine | OS |
| --- | --- | --- |
| `winterfell` | Desktop, Ryzen 7 9800X3D, RTX 5080 | NixOS |
| `winterfell-vm` | e2e test VM | NixOS |
| `dragonstone` | MacBook Pro M1 Pro | nix-darwin |

## Layout

- `modules/hosts/`: one file per machine
- `modules/users/`: user config
- `modules/features/`: reusable aspects (desktop, neovim, git, etc)
- `modules/installer.nix`: installer ISO and `infra-install`
- `scripts/`: helper scripts called from the justfile

## Usage

Run `just` to list recipes. Common ones:

```sh
just rebuild   # apply config to this machine
just check     # evaluate every host, ISO, and package
just update    # update flake inputs
just iso       # build the installer ISO
just vm        # run the e2e VM
```

## Install

Boot the installer ISO (`just iso`) and run `infra-install [host]`. It partitions with disko, sets up LUKS, installs, and clones this repo to `~/.config/infra`.

[!NOTE]: Root is ephemeral. Persisted paths live in `modules/features/preservation.nix`.

