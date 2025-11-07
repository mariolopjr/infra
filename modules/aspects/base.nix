{ infra, ... }:
{
  infra.base = {
    darwin = { };
    nixos = { };
    includes = [
      infra.bootable
      infra.documentation
      infra.hw-detect
      infra.greetd
      infra.plymouth
      infra.substituters
      infra.warn-dirty
    ];
  };
}
