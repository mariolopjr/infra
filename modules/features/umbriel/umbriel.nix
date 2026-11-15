{
  den.aspects.mario.homeManager =
    { lib, pkgs, ... }:
    {
      xdg.configFile."umbriel/config.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        source = ./config.toml;
      };
    };
}
