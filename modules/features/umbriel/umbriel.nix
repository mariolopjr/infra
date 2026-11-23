{
  den.aspects.desktop.provides.to-users.homeManager =
    { lib, pkgs, ... }:
    {
      xdg.configFile."umbriel/config.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        source = ./config.toml;
      };
    };
}
