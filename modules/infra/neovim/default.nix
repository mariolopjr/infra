{ inputs, ... }:
let
  inherit (inputs.nvf) lib;
  inherit (lib.nvim.binds) mkKeymap;
in
{
  flake-file.inputs.nvf.url = "github:notashelf/nvf";

  infra.neovim = _: {
    homeManager = {
      imports = [
        inputs.nvf.homeManagerModules.default
      ];

      programs.nvf = {
        enable = true;

        settings.vim = {
          viAlias = false;
          vimAlias = true;
          globals = {
            mapleader = " ";
            maplocalleader = " ";
            have_nerd_font = true;
            loaded_netrw = 1;
            loaded_netrwPlugin = 1;
          };

          theme = {
            enable = true;
            name = "catppuccin";
            style = "macchiato";
          };

          # lang support
          languages = {
            enableTreesitter = true;
            nix.enable = true;
            rust.enable = true;
          };
          lsp = {
            enable = true;
            formatOnSave = true;
          };
          treesitter.enable = true;

          # Editor enhancements (mini.nvim plugins)
          mini = {
            comment.enable = true;
            hipatterns.enable = true;
            pairs.enable = true;
            sessions.enable = true;
            snippets.enable = true;
            surround.enable = true;
          };

          ui.noice = {
            enable = true;
            setupOpts.presets = {
              bottom_search = true;
              command_palette = true;
              long_message_to_split = true;
            };
          };

          keymaps = [
            (mkKeymap "n" "<leader>fn" "<cmd>enew<CR>" { desc = "[F]ile [N]ew"; })
            (mkKeymap [ "n" "v" ] "<leader>fs" ":w<CR>" {
              desc = "[F]ile [S]ave";
            })
            (mkKeymap [ "n" "v" ] "<leader>fq" ":q<CR>" {
              desc = "[F]ile [Q]uit";
            })
            (mkKeymap [ "n" "v" ] "<leader>q" ":cquit<CR>" {
              desc = "[Q]uit Neovim";
              noremap = true;
              silent = true;
            })
          ];
        };
      };
    };
  };
}
