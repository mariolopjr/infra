{ infra, ... }:
let
  # private aspects can be let-bindings
  # more re-usable ones are better defined inside the `infra` namespace.
  host-contrib-to-user =
    { ... }: # replace with { user, host }:
    {
      homeManager = { };
    };

  common-user-env =
    { host, user }:
    {
      includes = map (f: f { inherit host user; }) [
        # add other aspects of yours that use host, user
        # to conditionally add behaviour.
        host-contrib-to-user
      ];
    };
in
{
  # set up hosts with users
  den.hosts.x86_64-linux.winterfell.users.mario = { };
  den.hosts.x86_64-linux.winterfell-kvm.users.mario = { };
  den.hosts.x86_64-linux.winterfell-vm.users.mario = { };
  den.hosts.x86_64-linux.winterfell-iso.users.mario = { };

  den.aspects.winterfell = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.hw
    ];

    nixos =
      { pkgs, ... }:
      {
        boot.kernelPackages = pkgs.linuxPackages_latest;

        disko.devices.disk.main = {
          device = "/dev/nvme0n1";
          content.partitions.luks.content = {
            content.subvolumes."/swap".swap.swapfile.size = "16G";
          };
        };
      };

    _.common-user-env = common-user-env;
  };

  den.aspects.winterfell-kvm = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.kvm
    ];

    nixos =
      { pkgs, ... }:
      {
        boot.kernelPackages = pkgs.linuxPackages_latest;

        environment.sessionVariables = {
          WLR_NO_HARDWARE_CURSORS = "1";
        };

        disko.devices.disk.main = {
          device = "/dev/vda";
          content.partitions.luks.content = {
            content.subvolumes."/swap".swap.swapfile.size = "4G";
          };
        };
      };

    _.common-user-env = common-user-env;
  };

  den.aspects.winterfell-vm = {
    includes = [
      infra.winterfell._.base
      infra.winterfell._.vm
    ];

    nixos =
      { pkgs, ... }:
      {
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # TODO: determine reason for duplicate systemd swap unit file
        disko.devices.disk.main = {
          device = "/dev/vda";
          imageSize = "40G";
          # TODO: redo this with a sops-encrypted key
          preCreateHook = ''
            echo -n 'secret' > /tmp/secret.key
          '';

          content.partitions.luks.content = {
            passwordFile = "/tmp/secret.key";

            content.subvolumes."/swap".swap.swapfile.size = "4G";
          };
        };
      };
  };

  den.aspects.winterfell-iso = {
    includes = [
      infra.winterfell._.iso
    ];
  };

  infra.winterfell.provides = {
    hw.includes = [
      infra.kvm-amd
      infra.nvidia
    ];

    kvm.includes = [
      infra.virtual
    ];

    vm.includes = [
      infra.virtual
    ];

    iso.includes = [
      infra.iso
      infra.nvidia
      infra.base
      infra.gaming
    ];

    base.includes = [
      infra.base
      infra.disko
      infra.gaming
    ];
  };
}
