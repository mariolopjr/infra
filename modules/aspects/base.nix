{ infra, ... }:
{
  infra.base = {
    darwin = { };
    nixos = { };
    includes = [
      infra.audio
      infra.bluetooth
      infra.bootable
      infra.documentation
      infra.hw-detect
      infra.mutable-users
      infra.substituters
      infra.sudo
      infra.timezone
      infra.warn-dirty
    ];
  };
}
