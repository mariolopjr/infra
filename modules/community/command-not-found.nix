{ inputs, ... }:
{
  flake-file.inputs = {
    nix-index-database.url = "github:nix-community/nix-index-database";
  };

  infra.command-not-found = _: {
    nixos = {
      imports = [
        inputs.nix-index-database.nixosModules.nix-index
      ];

      programs = {
        command-not-found.enable = false;
        nix-index.enable = true;
      };
    };

    homeManager = {
      programs.command-not-found.enable = false;
    };
  };
}
