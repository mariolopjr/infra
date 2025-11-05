# creates a `infra` aspect namespace.
#
{ config, lib, ... }:
{
  # create a sub-tree of provided aspects.
  den.aspects.profile.provides = { };
  # setup for write
  imports = [ (lib.mkAliasOptionModule [ "infra" ] [ "den" "aspects" "profile" "provides" ]) ];
  # setup for read
  _module.args.infra = config.den.aspects.profile.provides;
  # optionally expose outside your flake.
  # flake.infra = config.den.aspects.profile.provides;
}
