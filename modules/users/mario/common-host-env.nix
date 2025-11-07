# An aspect that contributes to any operating system where `mario` is a user.
{ infra, lib, ... }:
let
  # private aspects can be in variables
  # more re-usable ones are better defined inside the `infra` namespace.
  user-contrib-to-host =
    { user, ... }:
    lib.recursiveUpdate {
      nixos = {
        users.users.${user.userName} = {
          # TODO: change this from temp password to one encrypted by sops
          hashedPassword = "$y$j9T$89xirH4b8LCFTaHBWEoJG.$3MzGxJSgLYKQDP.JUSnZ4oNTLs7vdZyZcdI9f7TQNf3";
        };
      };
      darwin = { };
    } infra.state-version;
in
{
  den.aspects.mario._.common-host-env =
    { host, user }:
    {
      includes = map (f: f { inherit host user; }) [
        # add other aspects of yours that use host, user
        # to conditionally add behaviour.
        user-contrib-to-host
        infra.cli
        infra.command-not-found
        infra.fish
        infra.fonts
        infra.ghostty
        infra.hyprland
        infra.nix
        infra.nix-direnv
        infra.ssh
        infra.sops-nix

        infra.impermanence
      ];
    };
}
