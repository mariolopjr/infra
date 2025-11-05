{
  infra.nix = _: {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.nixd
          pkgs.cachix
        ];

        programs.nh.enable = true;
        programs.home-manager.enable = true;
      };
  };
}
