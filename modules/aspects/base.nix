{ infra, ... }:
{
  infra.base = {
    darwin = { };
    nixos = { };
    includes = [
      infra.audio
      infra.bootable
      infra.documentation
      infra.hw-detect
      infra.greetd
      infra.mutable-users
      infra.substituters
      infra.sudo
      infra.warn-dirty
    ];
  };
}
