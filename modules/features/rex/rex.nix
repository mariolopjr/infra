# Rex (Superlogical)
{ inputs, ... }:
{
  flake-file.inputs.rex = {
    url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz"; # no stable channel yet
    inputs.nixpkgs.follows = "nixpkgs";
  };

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
          homeManager = {
            services.rex.enable = true;
            programs.ssh.enable = true; # rex adds its SSH fallback to ~/.ssh/config
          };
          # Keep the user service (and its sessions) running while logged out.
          provides.to-hosts.nixos.users.users.mario.linger = true;
        }
      else
        {
          # Rex.app bundles the client, the server helper and its rex CLI.
          homeManager =
            { pkgs, ... }:
            let
              rexApp = pkgs.stdenvNoCC.mkDerivation (
                let
                  app = builtins.fromJSON (builtins.readFile ./app.json); # bumped by scripts/update-rex-app.sh
                in
                {
                  pname = "rex-app";
                  inherit (app) version;
                  src = pkgs.fetchurl { inherit (app) url hash; };
                  nativeBuildInputs = [ pkgs.undmg ];
                  sourceRoot = "Rex.app";
                  dontFixup = true; # any byte change breaks the code signature
                  installPhase = "mkdir -p $out/Applications/Rex.app && cp -R . $out/Applications/Rex.app";
                }
              );
            in
            {
              programs.rex.package = null;
              home.packages = [ rexApp ];
              # Rex iOS looks for the CLI on the non-interactive SSH PATH or here.
              home.file.".local/bin/rex".source =
                "${rexApp}/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
              # Nix controls when to update.
              targets.darwin.defaults."com.superlogical.rex".SUEnableAutomaticChecks = false;
            };
        }
    )
  ];
}
