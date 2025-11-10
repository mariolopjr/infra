{ inputs, ... }:
{
  flake-file.inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

  infra.nix = _: {
    nixos = {
      imports = [
        inputs.determinate.nixosModules.default
      ];
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
