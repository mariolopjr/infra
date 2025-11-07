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
      disko.devices.disk.main = {
        device = "/dev/vda";
        imageSize = "40G";

        content.partitions.luks.content = {
          passwordFile = "/tmp/secret.key";
          # TODO: redo this with a sops-encrypted key
          preCreateHook = ''
            echo -n 'secret' > /tmp/secret.key
          '';
        };
      };

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
