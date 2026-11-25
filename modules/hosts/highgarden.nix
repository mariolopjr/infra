# Raspberry Pi 5 on a 128GB SD card: Navidrome, Homebridge, LAN only.
# `just pi-flash` writes the card, `just pi-deploy` builds here and pushes over SSH, so the Pi
# itself never needs the internet.
#
# Card: FAT firmware partition (boot generations) + one btrfs partition with @root, @nix, @log,
# @persist. @root is deleted and recreated empty in the initrd every boot (no tmpfs: 4GB RAM).
{ inputs, den, ... }:
let
  label = "NIXOS_SD";
  subvol = name: {
    device = "/dev/disk/by-label/${label}";
    fsType = "btrfs";
    options = [
      "subvol=${name}"
      "compress=zstd:1"
      "noatime"
    ];
  };
in
{
  # Pi 5 kernel, firmware, bootloader and SD image
  flake-file.inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

  den.hosts.aarch64-linux.highgarden = {
    instantiate = inputs.nixos-raspberrypi.lib.nixosSystem; # Pi kernel overlays, on its own nixpkgs
    users.mario = { }; # slim home: no den.aspects.dev
  };

  # Appliances get the slim home: rex and the shared nvim, none of the dev aspect.
  perSystem =
    { pkgs, ... }:
    {
      checks.appliance =
        let
          hm = inputs.self.nixosConfigurations.highgarden.config.home-manager.users.mario or null;
        in
        if
          hm != null
          && hm.services.rex.enable
          && hm.xdg.dataFile ? "nvim/site/pack/nix-shared/start"
          && !(hm.xdg.configFile ? "nvim/lua/ide")
          && !(hm ? claude)
        then
          pkgs.emptyFile
        else
          throw "highgarden: mario's home should have rex and the shared nvim, without the dev aspect";

      # Plain HTTP stays on loopback; the LAN only sees Caddy's TLS, from a CA that survives reboots.
      checks.lan-tls =
        let
          cfg = inputs.self.nixosConfigurations.highgarden.config;
          vhosts = cfg.services.caddy.virtualHosts;
        in
        if
          cfg.services.navidrome.settings.Address == "127.0.0.1"
          && (cfg.services.homebridge.uiSettings.host or null) == "127.0.0.1"
          && vhosts ? "music.highgarden.lan"
          && vhosts ? "homebridge.highgarden.lan"
          && builtins.any (
            d: d.directory == "/var/lib/caddy"
          ) cfg.preservation.preserveAt."/persist".directories
        then
          pkgs.emptyFile
        else
          throw "highgarden: navidrome and the homebridge UI should sit on loopback behind caddy, with /var/lib/caddy persisted";
    };

  den.aspects.highgarden = {
    includes = [
      den.aspects.preservation
      den.aspects.egress
      den.aspects.homebridge
      den.aspects.mario-keys
      den.aspects.rex
    ];
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          inputs.home-manager.nixosModules.home-manager
          raspberry-pi-5.base
          sd-image
        ];
        boot.loader.limine.enable = lib.mkForce false; # the Pi firmware boots the kernel directly
        services.fwupd.enable = lib.mkForce false; # no UEFI capsules; metadata fetches are blocked anyway
        security.sudo.wheelNeedsPassword = false; # key-only SSH and no password set on this host

        sdImage = {
          rootVolumeLabel = label;
          rootFilesystemCreator = ./_highgarden-root.nix;
          nixPathRegistrationFile = "/nix/nix-path-registration";
        };
        fileSystems = {
          "/" = lib.mkForce (subvol "@root");
          "/nix" = subvol "@nix";
          "/var/log" = subvol "@log";
          "/persist" = subvol "@persist";
        };
        boot.initrd.systemd.services.root-reset = {
          description = "Recreate an empty @root";
          wantedBy = [ "initrd.target" ];
          requires = [ "dev-disk-by\\x2dlabel-${label}.device" ];
          after = [ "dev-disk-by\\x2dlabel-${label}.device" ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = false;
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /btrfs
            mount -t btrfs -o subvolid=5 /dev/disk/by-label/${label} /btrfs
            btrfs subvolume delete --recursive /btrfs/@root # systemd nests subvolumes under /var/lib
            btrfs subvolume create /btrfs/@root
            umount /btrfs
          '';
        };
        systemd.services.expand-root-partition = {
          path = with pkgs; [
            btrfs-progs
            gawk
            parted
            util-linux
          ];
          script = lib.mkForce ''
            part=$(findmnt -nvo SOURCE /nix)
            num=$(lsblk -npo MAJ:MIN "$part" | awk -F: '{print $2}')
            echo ",+," | sfdisk -N"$num" --no-reread "$(lsblk -npo PKNAME "$part")"
            partprobe
            btrfs filesystem resize max /nix
          '';
        };

        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/homebridge"; # pairing, accessory cache, Protect login
            user = "homebridge";
            group = "homebridge";
            mode = "0700";
          }
          {
            directory = "/var/lib/navidrome"; # library database, users
            user = "navidrome";
            group = "navidrome";
            mode = "0700";
          }
          {
            directory = "/var/lib/caddy"; # local CA root: devices trust it once
            user = "caddy";
            group = "caddy";
            mode = "0700";
          }
          {
            directory = "/srv/music";
            user = "mario";
            group = "users";
          }
        ];
        preservation.preserveAt."/persist".users.mario.directories = [
          ".local/state/rex" # host-id, server snapshots
          ".local/state/nvim" # undo, shada
        ];

        services.caddy = {
          enable = true;
          globalConfig = "skip_install_trust"; # the system trust store is read-only; clients trust the root
          virtualHosts."music.highgarden.lan".extraConfig = ''
            tls internal
            reverse_proxy 127.0.0.1:${toString config.services.navidrome.settings.Port}
          '';
          virtualHosts."homebridge.highgarden.lan".extraConfig = ''
            tls internal
            reverse_proxy 127.0.0.1:${toString config.services.homebridge.uiSettings.port}
          '';
        };
        services.homebridge.uiSettings.host = "127.0.0.1";

        services.navidrome = {
          enable = true;
          settings = {
            Address = "127.0.0.1";
            MusicFolder = "/srv/music";
            EnableInsightsCollector = false;
            EnableExternalServices = false; # Last.fm, Spotify, ListenBrainz: blocked by egress anyway
          };
        };
        systemd.tmpfiles.settings.navidromeDirs."/srv/music".d = lib.mkForce {
          user = "mario";
          group = "users";
          mode = "0755";
        };
      };
  };
}
