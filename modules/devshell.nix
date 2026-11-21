# Dev environment for editing this repo (language servers, formatters, just), via devenv's
# flake-parts module.
{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];
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
