{
  infra.nix = _: {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.nix-search-cli
          pkgs.nixd
          pkgs.cachix
        ];

        programs.nh.enable = true;
        programs.home-manager.enable = true;
      };
  };
}
