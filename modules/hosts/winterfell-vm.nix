# winterfell's disks and desktop in qemu for end-to-end tests: aarch64 (macOS HVF, Linux KVM)
# or x86_64 (KVM), per den.nix.
{ den, ... }:
{
  den.aspects.winterfell-vm = {
    includes = [
      den.aspects.disks
      den.aspects.desktop
      den.aspects.dev
    ];
    nixos =
      { modulesPath, ... }:
      {
        imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
        boot.initrd.availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "xhci_pci"
          "usbhid"
        ];
        boot.kernelParams = [ "console=tty0" ];
        boot.initrd.kernelModules = [ "virtio_gpu" ]; # firmware GOP is blit-only: no early framebuffer for plymouth
        services.qemuGuest.enable = true;
        nix.settings.extra-substituters = [ "http://10.0.2.2:5080?priority=10" ]; # `just vm-cache` on the host
      };
  };
}
