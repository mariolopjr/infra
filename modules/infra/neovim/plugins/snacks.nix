{ inputs, ... }:
let
  inherit (inputs.nvf) lib;
  inherit (lib.nvim.binds) mkKeymap;
in
{
  infra.neovim = _: {
    homeManager = {
      programs.nvf = {
        settings.vim = {
          utility.snacks-nvim = {
            enable = true;
            setupOpts = {
              bigfile.enable = true;

              dashboard = {
                enabled = true;
                sections = [
                  { section = "header"; }
                  {
                    icon = " ";
                    title = "Keymaps";
                    section = "keys";
                    indent = 2;
                    padding = 1;
                  }
                  {
                    icon = " ";
                    title = "Projects";
                    section = "projects";
                    indent = 2;
                    padding = 1;
                  }
                  {
                    icon = " ";
                    title = "Recent Files";
                    section = "recent_files";
                    indent = 2;
                    padding = 1;
                  }
                  # TODO: recreate snacks startup, with using stats and plugins loaded via nvf
                  # { section = "startup"; }
                ];
              };

              explorer.enable = true;
              indent.enable = true;
              input.enable = true;
              notifier.enable = true;

              image = {
                enable = true;
                math = false;
              };

              picker = {
                matcher = {
                  frecency = true;
                };

                win.input.keys = {
                  "<Esc>" = {
                    "@1" = "close";
                    mode = [
                      "n"
                      "i"
                    ];
                  };
                  # scroll like lazygit
                  "J" = {
                    "@1" = "preview_scroll_down";
                    mode = [
                      "n"
                      "i"
                    ];
                  };
                  "K" = {
                    "@1" = "preview_scroll_up";
                    mode = [
                      "n"
                      "i"
                    ];
                  };
                  "H" = {
                    "@1" = "preview_scroll_left";
                    mode = [
                      "n"
                      "i"
                    ];
                  };
                  "L" = {
                    "@1" = "preview_scroll_right";
                    mode = [
                      "n"
                      "i"
                    ];
                  };
                };
              };

              quickfile.enable = true;
              scroll.enable = true;
              statuscolumn.enabled = true;
              terminal.enabled = false;
              words.enable = true;
            };
          };

          keymaps = [
            # file explorer
            (mkKeymap [ "n" "v" ] "<leader>fe"
              # lua
              ''
                function()
                  local lsp_root = vim.lsp.buf.list_workspace_folders()[1]
                  Snacks.explorer({ cwd = lsp_root })
                end
              ''
              {
                desc = "[F]ile [E]xplorer (root dir)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>e"
              # lua
              ''
                function()
                  local lsp_root = vim.lsp.buf.list_workspace_folders()[1]
                  Snacks.explorer({ cwd = lsp_root })
                end
              ''
              {
                desc = "[E]xplorer (root dir)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>fE"
              # lua
              ''
                function() Snacks.explorer() end
              ''
              {
                desc = "[F]ile [󰘶E]xplorer (cwd)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>E"
              # lua
              ''
                function() Snacks.explorer() end
              ''
              {
                desc = "[󰘶E]xplorer (cwd)";
                lua = true;
              }
            )

            (mkKeymap [ "n" "v" ] "<leader>ff"
              # lua
              ''
                function() Snacks.picker.files() end
              ''
              {
                desc = "[F]ile [F]ind";
                lua = true;
              }
            )
          ];
        };
      };
    };
  };
}
