{ inputs, ... }:
{
  flake-file.inputs.nvf.url = "github:notashelf/nvf";

  infra.neovim = _: {
    homeManager = {
      imports = [
        inputs.nvf.homeManagerModules.default
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
              loaded_netrw = 1;
              loaded_netrwPlugin = 1;
            };

            # lang support
            languages = {
              enableTreesitter = true;
              nix.enable = true;
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
          };
        };
      };
    };
  };
}
