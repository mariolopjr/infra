{
  infra.gui = _: {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.gnucash
        ];
      };
  };
}
