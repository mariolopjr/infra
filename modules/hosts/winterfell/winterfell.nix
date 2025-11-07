{ infra, ... }:
{
  den.aspects.winterfell = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.hw
    ];

    nixos.disko.devices.disk.main.device = "/dev/nvme0n1";
  };

  den.aspects.winterfell-vm = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.vm
    ];

    nixos = {
      disko.devices.disk.main.device = "/dev/vda";
      disko.devices.disk.main.imageSize = "40G";
    };
  };

  infra.winterfell._ = {
    hw.includes = [
      infra.kvm-amd
    ];

    vm.includes = [
      infra.virtual
    ];

    base.includes = [
      infra.bootable
      infra.hw-detect
      infra.substituters
      infra.disko

      infra.desktop
    ];
  };
}
