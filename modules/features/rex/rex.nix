# Rex (Superlogical)
{ inputs, ... }:
{
  den.aspects.mario.homeManager = {
    imports = [ inputs.rex.homeManagerModules.default ];
    programs.rex = {
      enable = true;
      config = ./init.lua;
    };
  };

  den.aspects.mario.includes = [
    (
      { host, ... }:
      if host.class == "nixos" then
        {
          homeManager = { pkgs, ... }: {
            services.rex.enable = true;
            home.packages = [ inputs.rex-attach.packages.${pkgs.stdenv.hostPlatform.system}.rex-attach ];
            programs.ssh = {
              enable = true; # rex adds its SSH fallback to ~/.ssh/config
              enableDefaultConfig = false;
            };
          };
          # Keep the user service (and its sessions) running while logged out.
          provides.to-hosts.nixos.users.users.mario.linger = true;
        }
      else
        {
          homeManager.programs.rex.package = null;
        }
    )
  ];
}
