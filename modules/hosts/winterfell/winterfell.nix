{ infra, ... }:
{
  den.aspects.winterfell = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.hw
    ];
  };

  den.aspects.winterfell-vm = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.vm
    ];
  };

  infra.winterfell._ = {
    hw.includes = [
      infra.kvm-amd
      (infra.disko {
        device = "/dev/nvme0n1";
      })
    ];

    vm.includes = [
      infra.virtual
      (infra.disko {
        device = "/dev/vda";
        imageSize = "40G";
      })
    ];

    base.includes = [
      infra.bootable
      infra.hw-detect
      infra.substituters

      infra.desktop
    ];
  };
}
