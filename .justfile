hostname := if os() == "macos" { trim(shell('scutil --get "LocalHostName"')) } else { trim(shell('hostname -s')) }

alias up := update
alias fmt := format
alias c := check
alias wf := write-flake
alias bm := build
alias r := repl

[private]
default:
    @just --list

# ---------- local ---------- #
[group("local")]
update *inputs:
    nix flake update {{ inputs }}

[group("local")]
check *inputs:
    nix flake check {{ inputs }}

[group("local")]
write-flake *inputs:
    nix run .#write-flake

[group("local")]
repl *input:
    nix repl .#

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
[linux]
build-machine hostname=hostname *args:
    nh os build . --hostname "{{ hostname }}" --diff always {{ args }}

[group("machine")]
[macos]
build-machine hostname=hostname *args:
    nh darwin build . --hostname "{{ hostname }}" --diff always {{ args }}
