{
  description = "My infrastructure for all of my systems";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # nixos-unstable
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3"; # no follows: keeps FlakeHub cache hits

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    # .envrc overrides this with a file holding the repo path; devenv needs its root.
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    import-tree.url = "github:vic/import-tree";
    den.url = "github:denful/den/latest";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    preservation.url = "github:nix-community/preservation";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    rex.url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz"; # no stable channel yet
    rex.inputs.nixpkgs.follows = "nixpkgs";
    # Unofficial Linux rex client
    rex-attach.url = "github:nivox/rex-attach/013610aab7ab1108ee5c26d6ea486e45ce881019";
    rex-attach.inputs.nixpkgs.follows = "nixpkgs";
    rex-attach.inputs.rust-overlay.follows = "";

    # Peter Lowe's ad/tracker hosts list for OpenSnitch
    pgl-blocklist = {
      url = "file+https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext";
      flake = false;
    };
  };
}
