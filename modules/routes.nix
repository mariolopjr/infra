# Profiles are just aspects whose only job is to include other aspects
# based on the properties (context) of the host/user they are included in.
#
# Profiles are all concentrated under the `infra` namespace
{ infra, den, ... }:
let
  noop = _: { };

  by-platform-config = { host }: infra.${host.system} or noop;

  user-provides-host-config = { user, host }: infra.${user.aspect}._.${host.aspect} or noop;

  host-provides-user-config = { user, host }: infra.${host.aspect}._.${user.aspect} or noop;

  # route = locator: { user, host }@ctx:
  #   (locator ctx) ctx;

  # deadnix: skip
  route = locator: { user, host }@ctx: (locator ctx) ctx;
in
{
  # set global static settings
  den.default = {
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.11";
    homeManager.home.stateVersion = "25.11";
  };

  # install profiles as parametric aspects on all hosts/users
  den.default.includes = [
    den._.home-manager
    infra.host-name
  ];

  # route configuration into den namespace
  den.aspects.routes.includes = map route [
    user-provides-host-config
    host-provides-user-config
    by-platform-config
  ];
}
