# An aspect that contributes to any operating system where fido is a user.
{ westeros, lib, ... }:
let
  # private aspects can be in variables
  # more re-usable ones are better defined inside the `westeros` namespace.
  user-contrib-to-host =
    { user, ... }:
    lib.recursiveUpdate {
      nixos = {
        users.users.${user.userName} = {
          hashedPassword = "$y$j9T$89xirH4b8LCFTaHBWEoJG.$3MzGxJSgLYKQDP.JUSnZ4oNTLs7vdZyZcdI9f7TQNf3";
        };
      };
      darwin = { };
    } westeros.state-version;
in
{
  den.aspects.mario._.common-host-env =
    { host, user }:
    {
      includes = map (f: f { inherit host user; }) [
        # add other aspects of yours that use host, user
        # to conditionally add behaviour.
        user-contrib-to-host
        westeros.cli
      ];
    };
}
