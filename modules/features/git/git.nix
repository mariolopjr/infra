{
  den.aspects.mario.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.delta ]; # core.pager
      xdg.configFile."git/config".source = ./config;
      xdg.configFile."git/ignore".source = ./ignore;
    };
}
