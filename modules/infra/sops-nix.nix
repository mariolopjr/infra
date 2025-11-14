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
      nixos = {
        imports = [ inputs.sops-nix.nixosModules.sops ];

        sops = defaults // {
          # TODO: actual path for this for impermanence
          # sops.age.keyFile = "/persist/var/lib/sops-nix/key.txt";
          age.keyFile = "/var/lib/sops-nix/key.txt";
          secrets."${user.userName}-password".neededForUsers = true;
        };
      };

      homeManager = {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        sops = defaults // {
          # TODO: actual path for this for impermanence
          age.keyFile = "/home/${user.userName}/.config/sops/age/key.txt";
        };
      };
    };
}
