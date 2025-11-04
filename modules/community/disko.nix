{ inputs, ... }:
{
  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  westeros.disko.nixos = {
    disko.imports = [
      inputs.disko.nixosModules.disko
    ];
  };
}
