{
  inputs,
  ...
}:
{
  den.aspects.winterfell-vm.nixos = {
    imports = [
      inputs.disko.nixosModules.default
    ];

    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/vda";
        imageSize = "40G";
        content = {
          type = "gpt";
          partitions = {
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
              size = "4G";
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
                passwordFile = "/tmp/secret.key";
                # TODO: redo this with a sops-encrypted key
                preCreateHook = ''
                  echo -n 'secret' > /tmp/secret.key
                '';
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
