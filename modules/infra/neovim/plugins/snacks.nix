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
                    section = "keys";
                    gap = 1;
                    padding = 1;
                  }
                  {
                    icon = " ";
                    title = "Projects";
                    section = "projects";
                    indent = 2;
                    padding = 1;
                    pane = 2;
                  }
                  {
                    icon = " ";
                    title = "Recent Files";
                    section = "recent_files";
                    indent = 2;
                    padding = 1;
                    pane = 2;
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

                sources.explorer.win.list.keys = {
                  # alt+h interferes with pane resizing so remap to alt+.
                  "<A-.>" = {
                    "@1" = "toggle_hidden";
                    mode = [
                      "n"
                      "i"
                    ];
                  };
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
                  # alt+h interferes with pane resizing so remap to alt+.
                  "<A-.>" = {
                    "@1" = "toggle_hidden";
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

          keymaps =
            let
              getRootDir =
                #lua
                ''
                  --- Get the root directory using LSP or .git
                  --- @return string root_dir The root directory
                  local function get_root_dir()
                    --- @type string|nil
                    local lsp_root = vim.lsp.buf.list_workspace_folders()[1]
                    if lsp_root then
                      return lsp_root
                    end

                    -- fallback to searching for .git directory
                    --- @type string|nil
                    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
                    if vim.v.shell_error == 0 and git_root and git_root ~= "" then
                      return git_root
                    end

                    -- fallback to current working directory
                    --- @type string
                    return vim.fn.getcwd()
                  end
                '';
            in
            [
              (mkKeymap [ "n" "v" ] "<leader>/"
                # lua
                ''
                  function() Snacks.picker.grep() end
                ''
                {
                  desc = "[/] Grep";
                  lua = true;
                }
              )

              # git
              (mkKeymap [ "n" "v" ] "<leader>gg"
                # lua
                ''
                  function() Snacks.lazygit() end
                ''
                {
                  desc = "[G]it Lazy[G]it";
                  lua = true;
                }
              )

              # file explorer
              (mkKeymap [ "n" "v" ] "<leader>fe"
                # lua
                ''
                  function()
                    ${getRootDir}
                    Snacks.explorer({ cwd = get_root_dir() })
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
                    ${getRootDir}
                    Snacks.explorer({ cwd = get_root_dir() })
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

              # lsp
              (mkKeymap [ "n" "v" ] "gd"
                # lua
                ''
                  function() Snacks.picker.lsp_definitions() end
                ''
                {
                  desc = "[G]oto [D]efinitions";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "gr"
                # lua
                ''
                  function() Snacks.picker.lsp_references() end
                ''
                {
                  desc = "[G]oto [R]eferences";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "gI"
                # lua
                ''
                  function() Snacks.picker.lsp_implementations() end
                ''
                {
                  desc = "[G]oto [I]mplementation";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "gy"
                # lua
                ''
                  function() Snacks.picker.lsp_type_definitions() end
                ''
                {
                  desc = "[G]oto T[y]pe Definitions";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>ss"
                # lua
                ''
                  function() Snacks.picker.lsp_symbols() end
                ''
                {
                  desc = "[S]earch [S]ymbols";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sS"
                # lua
                ''
                  function() Snacks.picker.lsp_references() end
                ''
                {
                  desc = "[S]earch Reference[S]";
                  lua = true;
                }
              )
            ];
        };
      };
    };
  };
}
