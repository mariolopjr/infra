{ westeros, ... }:
{
  westeros.winterfell.includes = [
    westeros.winterfell._.base
    westeros.winterfell._.hw
  ];

  westeros.winterfell-vm.includes = [
    westeros.winterfell._.base
    westeros.winterfell._.vm
  ];

  westeros.winterfell.provides = {
    hw.includes = [
      westeros.bootable
      westeros.disko
      westeros.kvm-amd
    ];

    vm.includes = [
      # westeros.xfce-desktop
    ];

    base.includes = [
      westeros.hw-detect
    ];
  };
}
