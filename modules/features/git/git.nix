{
  den.aspects.mario.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.delta # core.pager
        pkgs.difftastic # diff.tool
        pkgs.git-lfs # filter.lfs
      ];
      xdg.configFile."git/config".source = ./config;
      xdg.configFile."git/ignore".source = ./ignore;
    };
}
