{ lib, ... }:
{
  infra.iso.nixos =
    { modulesPath, ... }:
    {
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
      ];

      isoImage = {
        makeEfiBootable = lib.mkDefault true;
        makeUsbBootable = lib.mkDefault true;
        edition = lib.mkDefault "winterfell-iso";
        volumeID = lib.mkDefault "WINTERFELL_ISO";
      };
    };
}
