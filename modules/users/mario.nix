# An aspect that contributes to any operating system where `mario` is a user.
{
  infra,
  lib,
  ...
}:
let
  # private aspects can be in variables
  # more re-usable ones are better defined inside the `infra` namespace.
  user-contrib-to-host =
    { user, ... }:
    lib.recursiveUpdate {
      nixos = {
        users.users.${user.userName} = {
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAipRk9CK71BwC7DtnYAsMX5CsuCbnq03YaOL7ZKX+bn"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhF7/5agjGzrAiS7eOH+tY5GhqdLKqbCuvGwkbR0lyr"
          ];

          extraGroups = [ "networkmanager" ];
        };
      };
      darwin = { };
    } infra.state-version;
in
{
  den.aspects.mario = {
    _.common-host-env =
      { host, user }:
      {
        includes = map (f: f { inherit host user; }) [
          # add other aspects of yours that use host, user
          # to conditionally add behaviour.
          user-contrib-to-host
          infra.catppuccin
          infra.cli
          infra.command-not-found
          infra.cooler-control
          infra.firefox
          infra.fish
          infra.fonts
          infra.git
          infra.hyprland
          infra.kde # alternative DE while hyprland config comes together
          infra.lact
          infra.nix
          infra.nix-direnv
          infra.neovim
          infra.ssh
          infra.sops-nix
          infra.ghostty

          infra.impermanence
        ];
      };
  };
}
