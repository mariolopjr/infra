{ den, ... }:
{
  den.hosts.x86_64-linux.winterfell.users.mario = { };
  den.hosts.x86_64-linux.winterfell-vm.users.mario = { };
  den.hosts.aarch64-darwin.targaryen.users.mario = { };
  den.aspects.mario.includes = [ den._.primary-user ];

  # den.default.includes = [
  #   den._.home-manager
  #   #
  #   # infra.single-user-is-admin
  # ];

  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.darwin = {
    url = "github:nix-darwin/nix-darwin/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
