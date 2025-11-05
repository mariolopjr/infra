{
  den,
  inputs,
  ...
}:
let
  vm =
    { device, imageSize }:
    {
      nixos = {
        disko.devices.disk.main.device = device;
        disko.devices.disk.main.imageSize = imageSize;
      };
    };

  hw =
    { device }:
    {
      nixos.disko.devices.disk.main.device = device;
    };
in
{
  infra.disko = {
    __functor = den.lib.parametric true;

    includes = [
      vm
      hw

      {
        nixos = {
          imports = [
            inputs.disko.nixosModules.default
          ];

          disko.devices = {
            disk.main = {
              type = "disk";
              # device = "/dev/nvme0n1";
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    size = "512M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
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
                            "/swap" = {
                              mountpoint = "/.swapvol";
                              swap.swapfile.size = "16G";
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
    ];
  };
}
