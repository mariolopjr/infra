# `, <cmd>` runs any nixpkgs program without installing it
{ inputs, ... }:
{
  den.default.nixos = {
    imports = [ inputs.nix-index-database.nixosModules.default ];
    programs.nix-index-database.comma.enable = true;
  };

  den.default.darwin = {
    imports = [ inputs.nix-index-database.darwinModules.default ];
    programs.nix-index-database.comma.enable = true;
  };
}
