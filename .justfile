hostname := if os() == "macos" { trim(shell('scutil --get "LocalHostName"')) } else { trim(shell('hostname -s')) }

alias up := update
alias fmt := format
alias c := check
alias wf := write-flake
alias fm := metadata
alias r := repl
alias bm := build

[private]
default:
    @just --list

# ---------- nix ---------- #
[group("nix")]
update *inputs:
    nix flake update {{ inputs }}

[group("nix")]
check *inputs:
    nix flake check {{ inputs }}

[group("nix")]
metadata flake-url="." *inputs:
    nix flake metadata {{ flake-url }} {{ inputs }}

[group("nix")]
write-flake *inputs:
    nix run .#write-flake

[group("nix")]
repl *input:
    nix repl .#

[group("nix")]
format *args:
    nix run .#fmt

[group("nix")]
vm *args:
    nix run .#vm

# ---------- local ---------- #
[group("local")]
build *args:
    @just build-machine {{ hostname }} {{ args }}

# ---------- machine ---------- #
[group("machine")]
[linux]
build-machine hostname=hostname *args:
    nh os build . --hostname "{{ hostname }}" --diff always {{ args }}

[group("machine")]
[macos]
build-machine hostname=hostname *args:
    nh darwin build . --hostname "{{ hostname }}" --diff always {{ args }}
