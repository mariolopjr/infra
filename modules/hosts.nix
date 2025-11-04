{ westeros, den, inputs, ... }:
{
  den.hosts.x86_64-linux.winterfell.users.mario = { };

  den.default.host._.host.includes = [
    # westeros.host-profile
    den._.home-manager
    (den._.import-tree._.host { root = ../non-den/hosts; })
  ];

  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
