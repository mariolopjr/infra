# Two-disk LUKS + btrfs layout, tmpfs root and /home (state on @persist, caches on @cache, see preservation.nix). Devices come from the host's `disks.{main,data}`.
{ inputs, ... }:
let
  luks = name: content: {
    type = "luks";
    inherit name content;
    passwordFile = "/tmp/luks.key"; # only used during install
    settings = {
      allowDiscards = true;
      bypassWorkqueues = true; # dm-crypt workqueues only add latency on NVMe
    };
  };
  btrfsOpts = [
    "compress=zstd:1"
    "noatime"
  ];
in
{
  den.aspects.disks.includes = [
    (
      { host, ... }:
      {
        nixos = {
          imports = [ inputs.disko.nixosModules.disko ];
          disko.devices.disk.main = {
            type = "disk";
            device = host.disks.main;
            content = {
              type = "gpt";
              partitions.ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              partitions.root = {
                size = "100%";
                content = luks "cryptroot" {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = btrfsOpts;
                    };
                    "@persist/.snapshots" = { }; # snapper's, visible at /persist/.snapshots
                    "@cache" = {
                      mountpoint = "/cache";
                      mountOptions = btrfsOpts;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = btrfsOpts;
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = btrfsOpts;
                    };
                    "@swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
          disko.devices.nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "size=25%"
              "mode=755"
            ];
          };
          disko.devices.disk.data = {
            type = "disk";
            device = host.disks.data;
            content = {
              type = "gpt";
              partitions.data = {
                size = "100%";
                content = luks "cryptdata" {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes."@data" = {
                    mountpoint = "/data";
                    mountOptions = btrfsOpts;
                  };
                };
              };
            };
          };
          services.btrfs.autoScrub.enable = true;
          boot.kernelParams = [
            "zswap.enabled=1"
            "zswap.shrinker_enabled=1"
          ];
        };
      }
    )
  ];
}
