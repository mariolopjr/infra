# Heavier home config for non-appliance and non-handheld gaming devices, for every user on
# the host that includes it.
{ den, ... }:
{
  den.aspects.dev.provides.to-users = {
    includes = with den.aspects; [
      claude
      ghostty
      yazi
      neovim-ide
    ];
    homeManager =
      { pkgs, ... }:
      {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        home.packages = [
          pkgs.age
          pkgs.claude-code
          pkgs.devenv
          pkgs.f3
          pkgs.just
        ];
      };
  };
}
