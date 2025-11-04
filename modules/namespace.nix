# creates a `westeros` aspect namespace.
#
{ config, lib, ... }:
{
  # create a sub-tree of provided aspects.
  den.aspects.profile.provides = { };
  # setup for write
  imports = [ (lib.mkAliasOptionModule [ "westeros" ] [ "den" "aspects" "profile" "provides" ]) ];
  # setup for read
  _module.args.westeros = config.den.aspects.profile.provides;
  # optionally expose outside your flake.
  flake.westeros = config.den.aspects.profile.provides;
}
