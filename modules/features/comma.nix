# `, <cmd>` runs any nixpkgs program without installing it
{ inputs, ... }:
{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.default.nixos = {
    imports = [ inputs.nix-index-database.nixosModules.default ];
    programs.nix-index-database.comma.enable = true;
  };

  den.default.darwin = {
    imports = [ inputs.nix-index-database.darwinModules.default ];
    programs.nix-index-database.comma.enable = true;
  };
}
