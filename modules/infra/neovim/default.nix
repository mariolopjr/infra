{ inputs, ... }:
{
  flake-file.inputs.nvf.url = "github:notashelf/nvf";

  infra.neovim = _: {
    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.nvf.nixosModules.default
        ];

        programs.nvf = {
          enable = true;

          settings = {
            vim = {
              viAlias = false;
              vimAlias = true;
              globals = {
                mapleader = " ";
                maplocalleader = " ";
                have_nerd_font = true;
              };

              # OS-wide plugins that should be on every host
              lazy = {
                enable = true;

                plugins = {
                  "mini.nvim" = {
                    package = pkgs.vimPlugins.mini-nvim;
                    lazy = false;
                  };
                };
              };
              autopairs.nvim-autopairs.enable = true;
            };
          };
        };
      };

    homeManager = {
      imports = [
        inputs.nvf.homeManagerModules.default
      ];

      programs.nvf = {
        enable = true;

        settings = {
          vim = {
            globals = {
              loaded_netrw = 1;
              loaded_netrwPlugin = 1;
            };
          };
        };
      };
    };
  };
}
