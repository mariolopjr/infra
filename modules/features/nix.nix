{ inputs, ... }:
let
  shared = import ../_caches.nix;
  caches = {
    extra-substituters = shared.substituters;
    extra-trusted-public-keys = shared.keys;
  };
in
{
  den.default.nixos = {
    imports = [ inputs.determinate.nixosModules.default ];
    nix.settings = caches // {
      trusted-users = [ "@wheel" ];
      eval-cores = 0;
    };
    nixpkgs.config.allowUnfree = true;
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
