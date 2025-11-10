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

          utility.snacks-nvim = {
            enable = true;
            setupOpts = {
              bigfile.enable = true;
              explorer.enable = true;
              image = {
                enable = true;
                math = false;
              };
              notifier.enable = true;
              picker = {
                matcher = {
                  frecency = true;
                };
              };
              quickfile.enable = true;
              terminal = {
                keys = {
                  q = "hide";
                };
              };

              # Indent guides and scope visualization
              indent = {
                enable = true;
                char = "│";
                only_scope = false;
                only_current = false;
                animate = {
                  enabled = true;
                  style = "out";
                  easing = "linear";
                  duration = {
                    step = 20;
                    total = 500;
                  };
                };
              };

              # LSP reference highlighting with navigation
              words = {
                enable = true;
                debounce = 200;
                notify_jump = false;
                notify_end = true;
                foldopen = true;
                jumplist = true;
                modes = [
                  "n"
                  "i"
                  "c"
                ];
              };

              # Smooth scrolling
              scroll = {
                enable = true;
                animate = {
                  duration = {
                    step = 15;
                    total = 250;
                  };
                  easing = "linear";
                };
              };
            };
          };
        };
      };
    };
  };
  };
}
