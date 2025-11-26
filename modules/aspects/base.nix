{ infra, ... }:
{
  infra.base = {
    darwin = { };
    nixos = { };
    includes = [
      infra.bootable
      infra.systemd-boot
      infra.documentation
      infra.hw-detect
      infra.greetd
      infra.substituters
      infra.sudo
      infra.warn-dirty
    ];
  };
}
