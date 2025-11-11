{
  infra.virtual.nixos = {
    boot.initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "sr_mod"

      "virtio"
      "virtio_blk"
      "virtio_pci"
      "virtio_scsi"
    ];
    boot.kernelModules = [ ];

    # set options for disko
    virtualisation.vmVariantWithDisko = {
      virtualisation.diskSize = 40960; # 40GB in Mb
      virtualisation.memorySize = 4096; # 4GB in Mb
    };

    # guest additions
    # services.qemuGuest.enable = true;
    # services.spice-vdagentd.enable = true;
  };
}
