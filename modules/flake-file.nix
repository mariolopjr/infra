# Core inputs. The rest of the inputs are withing the modules that use them (see README).
{ inputs, ... }:
{
  imports = [ inputs.flake-file.flakeModules.default ];

  flake-file = {
    description = "My infrastructure for all of my systems";
    outputs = "dendritic"; # flake-parts.lib.mkFlake over import-tree ./modules
    inputs = {
      nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # nixos-unstable
      flake-parts.url = "github:hercules-ci/flake-parts";
      flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
      import-tree.url = "github:vic/import-tree";
      flake-file.url = "github:denful/flake-file";
    };
  };
}
