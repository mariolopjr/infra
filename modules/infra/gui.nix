{
  infra.gui = _: {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.calibre
          pkgs.libreoffice
          pkgs.plexamp
        ];
      };
  };
}
