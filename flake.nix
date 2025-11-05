# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    den = {
      url = "github:vic/den";
    };
    disko = {
      url = "github:nix-community/disko";
    };
    flake-aspects = {
      url = "github:vic/flake-aspects";
    };
    flake-file = {
      url = "github:vic/flake-file";
    };
    flake-parts = {
      inputs = {
        nixpkgs-lib = {
          follows = "nixpkgs-lib";
        };
      };
      url = "github:hercules-ci/flake-parts";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager";
    };
    hyprland = {
      url = "github:hyprwm/hyprland";
    };
    hyprland-contrib = {
      inputs = {
        nixpkgs = {
          follows = "hyprland/nixpkgs";
        };
      };
      url = "github:hyprwm/contrib";
    };
    hyprpicker = {
      inputs = {
        hyprutils = {
          follows = "hyprland/hyprutils";
        };
        hyprwayland-scanner = {
          follows = "hyprland/hyprwayland-scanner";
        };
        nixpkgs = {
          follows = "hyprland/nixpkgs";
        };
        systems = {
          follows = "hyprland/systems";
        };
      };
      url = "github:hyprwm/hyprpicker";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    nix-auto-follow = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:fzakaria/nix-auto-follow";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    nixpkgs-lib = {
      follows = "nixpkgs";
    };
    systems = {
      url = "github:nix-systems/default";
    };
    treefmt-nix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:numtide/treefmt-nix";
    };
  };

}
