{ inputs, ... }:
{
  flake-file.inputs.disko.url = "github:nix-community/disko";

  imports = [
    inputs.disko.flakeModules.default
  ];

  westeros.disko = {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content =
                  let
                    mountOptions = [
                      "compress=zstd"
                      "ssd"
                      "noatime"
                      "discard=async"
                    ];
                  in
                  {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    postCreateHook = ''
                      MNTPOINT=$(mktemp -d)
                      mount "/dev/mapper/cryptroot" "$MNTPOINT" -o subvol=/
                      trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                      btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
                    '';
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/";
                        inherit mountOptions;
                      };
                      "/persist" = {
                        mountpoint = "/persist";
                        inherit mountOptions;
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        inherit mountOptions;
                      };
                    };
                  };
              };
            };
          };
        };
      };
    };
  };
}
