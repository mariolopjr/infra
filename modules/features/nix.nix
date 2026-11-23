{ inputs, ... }:
let
  shared = import ../_caches.nix;
  caches = {
    extra-substituters = shared.substituters;
    extra-trusted-public-keys = shared.keys;
  };
in
{
  # no follows: keeps FlakeHub cache hits
  flake-file.inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

  den.default.nixos = {
    imports = [ inputs.determinate.nixosModules.default ];
    nix.settings = caches // {
      trusted-users = [ "@wheel" ];
      eval-cores = 0;
      download-buffer-size = 256 * 1024 * 1024; # 256 MiB
    };
    nixpkgs.config.allowUnfree = true;
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 20 --keep-since 14d"; # 20 matches limine's maxGenerations
      };
    };
    documentation.nixos.enable = false; # skips rebuilding the options manual on module changes
  };

  den.default.darwin = {
    imports = [ inputs.determinate.darwinModules.default ];
    nixpkgs.config.allowUnfree = true;
    determinateNix = {
      enable = true;
      customSettings = caches // {
        trusted-users = [ "@admin" ];
        eval-cores = 0;
        use-case-hack = false; # store is case-sensitive APFS (installer's --extra-conf)
      };
      nixosVmBasedLinuxBuilder = {
        enable = true;
        config.virtualisation = {
          cores = 6;
          darwin-builder.memorySize = 12 * 1024;
          darwin-builder.diskSize = 100 * 1024;
        };
      };
    };
  };
}
