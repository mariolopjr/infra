{ inputs, ... }:
let
  defaults = {
    defaultSopsFile = ../../secrets/global.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = true;
  };
in
{
  flake-file.inputs = {
    sops-nix.url = "github:Mic92/sops-nix";
  };

  infra.sops-nix =
    { user, ... }:
    {
      nixos =
        { lib, config, ... }:
        {
          imports = [ inputs.sops-nix.nixosModules.sops ];

          sops = defaults // {
            age.keyFile = lib.mkDefault "/var/lib/sops-nix/keys.txt";
            secrets."${user.userName}-password".neededForUsers = true;
          };

          users.users.${user.userName} = {
            hashedPasswordFile = config.sops.secrets."${user.userName}-password".path;
          };
        };

      homeManager = {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        sops = defaults // {
          age.keyFile = "/home/${user.userName}/.config/sops/age/keys.txt";
        };
      };
    };
}
