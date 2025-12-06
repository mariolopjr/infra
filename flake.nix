# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    betterfox = {
      url = "github:HeitorAugustoLN/betterfox-nix";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
    };
    darwin = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-darwin/nix-darwin/master";
    };
    den = {
      url = "github:vic/den";
    };
    disko = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
    hypridle = {
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
      url = "github:hyprwm/hypridle";
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
    hyprlock = {
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
      url = "github:hyprwm/hyprlock";
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
    impermanence = {
      url = "github:nix-community/impermanence";
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
    nix-index-database = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/nix-index-database";
    };
    nixcord = {
      url = "github:kaylorben/nixcord";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    nixpkgs-lib = {
      follows = "nixpkgs";
    };
    nur = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/NUR";
    };
    nvf = {
      url = "github:notashelf/nvf";
    };
    plasma-manager = {
      inputs = {
        home-manager = {
          follows = "home-manager";
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/plasma-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
