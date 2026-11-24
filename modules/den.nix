{
  inputs,
  lib,
  den,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  flake-file.inputs = {
    den.url = "github:denful/den/latest";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
  den.schema.host.includes = [
    den.batteries.hostname
    den.batteries.mutual-provider
  ];

  den.default.nixos.system.stateVersion = lib.mkDefault "26.11";
  den.default.darwin.system.stateVersion = lib.mkDefault 6;
  den.default.homeManager.home.stateVersion = lib.mkDefault "26.11";
  den.default.os.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true; # /etc/profiles/per-user/<user>
    backupFileExtension = "pre-hm";
  };
}
