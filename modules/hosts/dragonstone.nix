# MacBook Pro M1 Pro
{ den, ... }:
{
  den.aspects.dragonstone = {
    includes = [ den.aspects.workstation ];
    darwin =
      { pkgs, ... }:
      {
        nixpkgs.hostPlatform = "aarch64-darwin";
        environment.systemPackages = with pkgs; [
          container
          crossover
        ];
        services.openssh = {
          enable = true;
          extraConfig = ''
            PasswordAuthentication no
            KbdInteractiveAuthentication no
            PermitRootLogin no
          '';
        };
      };
  };
}
