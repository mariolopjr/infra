{ den, ... }:
{
  den.aspects.desktop = {
    # darwin = ...;
    # nixos  = ...; #
    includes = with den.aspects; [ ];
  };
}
