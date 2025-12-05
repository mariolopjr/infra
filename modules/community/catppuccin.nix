{
  inputs,
  ...
}:
{
  flake-file.inputs.catppuccin.url = "github:catppuccin/nix";

  infra.catppuccin = _: {
    nixos = {
      imports = [ inputs.catppuccin.nixosModules.catppuccin ];

      catppuccin = {
        enable = true;
        flavor = "macchiato";
      };
    };

    homeManager = {
      imports = [ inputs.catppuccin.homeModules.catppuccin ];

      catppuccin = {
        enable = true;
        flavor = "macchiato";
      };
    };
  };
}
