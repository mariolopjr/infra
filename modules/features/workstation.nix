# Packages for non-server, non-handheld systems
{ den, ... }:
{
  den.aspects.workstation = {
    includes = [ den.aspects.dev ];
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.ncdu ];
        fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.rsync ]; # NixOS ships it by default
      };
  };
}
