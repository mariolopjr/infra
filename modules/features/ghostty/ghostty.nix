{
  den.aspects.mario.homeManager =
    { lib, pkgs, ... }:
    let
      darwin = pkgs.stdenv.hostPlatform.isDarwin;
    in
    {
      home.packages = [
        (if darwin then pkgs.ghostty-bin else pkgs.ghostty)
        pkgs.chafa # images in terminal
      ];
      xdg.configFile."ghostty/config".source = ./config;
      xdg.configFile."ghostty/macos" = lib.mkIf darwin { source = ./macos; };
    };
}
