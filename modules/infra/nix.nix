{ inputs, ... }:
{
  infra.nix = _: {
    nixos = {
      imports = [
        inputs.nur.modules.nixos.default
      ];

      # TODO: only allow specific packages
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowUnfreePredicate = (_: true);

      nix.settings.experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };

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
