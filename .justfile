hostname := shell("hostname -s")

alias up := update
alias fmt := format
alias c := check
alias wf := write-flake
alias bm := build

[private]
default:
    @just --list

# ---------- local ---------- #
[group("local")]
update *inputs:
    nix flake update {{ inputs }}

check *inputs:
    nix flake check {{ inputs }}

write-flake *inputs:
    nix run .#write-flake

[group("local")]
build *args:
    @just build-machine {{ hostname }} {{ args }}

[group("local")]
format *args:
    nix run .#fmt

[group("local")]
vm *args:
    nix run .#vm

# ---------- machine ---------- #
[group("machine")]
build-machine hostname=hostname *args:
    nh os build . --hostname "{{ hostname }}" --diff always {{ args }}
