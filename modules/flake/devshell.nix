# Dev environment for editing this repo (language servers, formatters, just), via devenv's
# flake-parts module.
{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];
  flake-file.inputs = {
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    # .envrc overrides this with a file holding the repo path; devenv needs its root.
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
  };
  perSystem =
    { lib, pkgs, ... }:
    {
      devenv.shells.default = {
        devenv.root =
          let
            root = builtins.readFile inputs.devenv-root.outPath;
          in
          lib.mkIf (root != "") root;
        containers = lib.mkForce { }; # devenv's container outputs need nix2container; unused here
        packages = [
          pkgs.cspell
          pkgs.just
          pkgs.lua-language-server
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.stylua
        ];
      };
    };
}
