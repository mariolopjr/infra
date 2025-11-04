{ westeros, ... }:
{
  den.aspects.winterfell = {
    includes = [
      westeros.winterfell._.base
      westeros.winterfell._.hw
    ];
  };

  den.aspects.winterfell-vm = {
    includes = [
      westeros.winterfell._.base
      westeros.winterfell._.vm
    ];
  };

  westeros.winterfell.provides = {
    hw.includes = [
      westeros.kvm-amd
    ];

    vm.includes = [
      westeros.virtual
    ];

    base.includes = [
      westeros.bootable
      westeros.hw-detect
    ];
  };
}
