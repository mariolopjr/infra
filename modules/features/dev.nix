# Heavier home config for non-appliance and non-handheld gaming devices.
# Feature files add to den.aspects.dev.provides.to-users.homeManager.
{
  den.aspects.dev.provides.to-users.homeManager =
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
}
