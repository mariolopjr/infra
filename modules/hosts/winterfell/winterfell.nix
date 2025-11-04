{ westeros, ... }:
{
  westeros.winterfell.includes = [
    westeros.winterfell._.base
    westeros.winterfell._.hw
  ];

  # westeros.winterfell-vm.includes = [
  #   westeros.nargun._.base
  #   westeros.nargun._.vm
  # ];

  westeros.winterfell.provides = {
    # for real-world hw machine
    hw.includes = [
      westeros.bootable
      # westeros.disko
      westeros.kvm-amd
    ];

    vm.includes = [
      # westeros.xfce-desktop
    ];

    base.includes = [
      # westeros.dev-laptop
    ];
  };
}
