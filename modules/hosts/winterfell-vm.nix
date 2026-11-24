# winterfell's disks and desktop in qemu for end-to-end tests: aarch64 (macOS HVF, Linux KVM)
# or x86_64 (KVM), one host per arch: `just vm` boots the one matching the machine it runs on.
{ den, ... }:
let
  vm = {
    hostName = "winterfell-vm";
    aspect = den.aspects.winterfell-vm;
    disks.main = "/dev/disk/by-id/virtio-main";
    disks.data = "/dev/disk/by-id/virtio-data";
    users.mario = { };
  };
in
{
  den.hosts.x86_64-linux.winterfell-vm-x86_64 = vm;
  den.hosts.aarch64-linux.winterfell-vm-aarch64 = vm;

  den.aspects.winterfell-vm = {
    includes = [
      den.aspects.disks
      den.aspects.desktop
      den.aspects.dev
      den.aspects.mario-keys # `just vm-ssh`
      den.aspects.rex
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
