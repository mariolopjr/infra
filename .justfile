hostname := if os() == "macos" { trim(shell('scutil --get "LocalHostName"')) } else { trim(shell('hostname -s')) }

alias up := update
alias fmt := format
alias c := check
alias wf := write-flake
alias bm := build
alias r := repl
alias s := switch
alias b := boot
alias t := test

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
switch *args:
    @just switch-machine {{ hostname }} {{ args }}

[group("local")]
boot *args:
    @just boot-machine {{ hostname }} {{ args }}

[group("local")]
test *args:
    @just test-machine {{ hostname }} {{ args }}

[group("local")]
format *args:
    nix run .#fmt

[group("local")]
vm *args:
    nix run .#vm

# TODO: use nh to build iso in the future
[group("local")]
iso *args:
    nix build .#nixosConfigurations.winterfell-iso.config.system.build.isoImage {{ args }}

# ---------- machine ---------- #
[group("machine")]
[linux]
build-machine hostname=hostname *args:
    nh os build . --hostname "{{ hostname }}" --diff always {{ args }}

[group("machine")]
[macos]
build-machine hostname=hostname *args:
    nh darwin build . --hostname "{{ hostname }}" --diff always {{ args }}

[group("machine")]
[linux]
switch-machine hostname=hostname *args:
    nh os switch . --hostname "{{ hostname }}" --diff always {{ args }}

[group("machine")]
[linux]
boot-machine hostname=hostname *args:
    nh os boot . --hostname "{{ hostname }}" --diff always {{ args }}

[group("machine")]
[linux]
test-machine hostname=hostname *args:
    nh os test . --hostname "{{ hostname }}" --diff always {{ args }}
