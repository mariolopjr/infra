{ ... }:
{
  infra.virtual.nixos = {
    boot.initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "sr_mod"
      "virtio_blk"
    ];
    boot.kernelModules = [ ];

    # set options for disko
    virtualisation.vmVariantWithDisko = {
      virtualisation.diskSize = 40960; # 40GB in Mb
      virtualisation.memorySize = 4096; # 4GB in Mb
    };
  };
}
