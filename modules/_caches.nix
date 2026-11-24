# Binary caches for noctalia, umbriel, nix-community and Raspberry Pi kernel builds. Used by features/nix.nix (hosts) and
# flake/installer.nix (ISOs and infra-install).
{
  substituters = [
    "https://noctalia.cachix.org"
    "https://umbriel.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixos-raspberrypi.cachix.org"
  ];
  keys = [
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
  ];
}
