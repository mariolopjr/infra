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

  infra.winterfell.provides = {
    hw.includes = [
      infra.kvm-amd
    ];

    vm.includes = [
      infra.virtual
    ];

    base.includes = [
      infra.base
    ];
  };
}
