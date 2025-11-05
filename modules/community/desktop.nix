{ infra, ... }:
{
  infra.desktop = {
    darwin = { };
    nixos = { };
    includes = [
      infra.greetd
      infra.hyprland
    ];
  };
}
