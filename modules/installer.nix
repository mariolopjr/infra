# `infra-install [host]` (this arch's hosts or asks when several are available), on the installer ISOs (this flake at /etc/infra) or the stock NixOS ISO via `nix run`:
# check disks, ask per disk whether to format (kept disks are unlocked and mounted), LUKS
# passphrase, disko, nixos-install, clone this repo to /persist/home/mario/.config/infra. Password hash goes on /persist.
# Online install: inputs and the system closure are fetched/built during install.
{ inputs, lib, ... }:
let
  # Binary caches for the closure; the custom ISO sets them in nix.conf, the script via NIX_CONFIG.
  shared = import ./_caches.nix;
  caches = {
    substituters = shared.substituters ++ [
      "https://install.determinate.systems" # prebuilt Determinate Nix
    ];
    keys = shared.keys ++ [
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
      "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
      "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
      "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
      "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
      "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
      "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
    ];
  };
  # vm: the e2e VM's ISO. It also tries `just vm-cache` (the host's store and checkout) at
  # qemu's host address. Plain ISOs due not use the local cache.
  infraInstall =
    pkgs: system: vm:
    pkgs.writeShellApplication {
      name = "infra-install";
      runtimeInputs = [
        inputs.disko.packages.${system}.disko
        pkgs.cryptsetup
        pkgs.git
        pkgs.gptfdisk
        pkgs.mkpasswd
        pkgs.parted
        pkgs.util-linux
      ];
      runtimeEnv = {
        INFRA_SELF = "${inputs.self}";
        INFRA_SUBSTITUTERS = toString caches.substituters;
        INFRA_KEYS = toString caches.keys;
        INFRA_CLONE_URLS = toString (
          lib.optional vm "git://10.0.2.2/infra" ++ [ "https://github.com/mariolopjr/infra.git" ]
        );
      };
      text = builtins.readFile ./infra-install.sh;
    };
  installer =
    system: vm:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        (
          { modulesPath, pkgs, ... }:
          {
            imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
            nixpkgs.hostPlatform = system;
            nix.settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              extra-substituters = caches.substituters ++ lib.optional vm "http://10.0.2.2:5080?priority=10";
              extra-trusted-public-keys = caches.keys;
            };
            networking.networkmanager.enable = true;
            networking.wireless.enable = lib.mkForce false;
            environment.etc.infra.source = inputs.self;
            environment.systemPackages = [
              pkgs.git
              inputs.disko.packages.${system}.disko
              (infraInstall pkgs system vm)
            ];
          }
        )
      ];
    };
in
{
  flake.nixosConfigurations = {
    installer-x86_64 = installer "x86_64-linux" false;
    installer-aarch64 = installer "aarch64-linux" false;
    installer-vm-x86_64 = installer "x86_64-linux" true;
    installer-vm-aarch64 = installer "aarch64-linux" true;
  };

  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (lib.hasSuffix "linux" system) {
      # `nix run github:mariolopjr/infra#infra-install -- <host>` from the stock NixOS ISO.
      packages.infra-install = infraInstall pkgs system false;
      packages.iso =
        inputs.self.nixosConfigurations."installer-${lib.head (lib.splitString "-" system)}".config.system.build.isoImage;
    };
}
