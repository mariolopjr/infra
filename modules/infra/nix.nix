{ inputs, ... }:
{
  flake-file.inputs.determinate = {
    url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  infra.nix = _: {
    nixos = {
      imports = [
        inputs.determinate.nixosModules.default
        inputs.nur.modules.nixos.default
      ];

      # TODO: only allow specific packages
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowUnfreePredicate = (_: true);

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
