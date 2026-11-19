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
  den.aspects.highgarden = {
    includes = [
      den.aspects.preservation
      den.aspects.egress
      den.aspects.homebridge
    ];
    nixos =
      { lib, pkgs, ... }:
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          inputs.home-manager.nixosModules.home-manager # no users; den.default sets its options
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
            directory = "/srv/music";
            user = "mario";
            group = "users";
          }
        ];

        services.navidrome = {
          enable = true;
          settings = {
            Address = "0.0.0.0";
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
