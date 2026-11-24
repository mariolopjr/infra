# MacBook Pro M1 Pro
{ den, ... }:
{
  den.hosts.aarch64-darwin.dragonstone.users.mario = { };

  den.aspects.dragonstone = {
    includes = [
      den.aspects.workstation
      den.aspects.mario-keys
      den.aspects.rex
    ];
    darwin =
      { pkgs, ... }:
      {
        nixpkgs.hostPlatform = "aarch64-darwin";
        environment.systemPackages = with pkgs; [
          container
          crossover
          discord
        ];
        determinateNix.nixosVmBasedLinuxBuilder = {
          enable = true;
          config.virtualisation = {
            cores = 6;
            darwin-builder.memorySize = 12 * 1024;
            darwin-builder.diskSize = 100 * 1024;
          };
        };
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
