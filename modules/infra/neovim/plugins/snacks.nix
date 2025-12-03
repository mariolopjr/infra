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
              # general
              (mkKeymap [ "n" "v" ] "<leader>,"
                # lua
                ''
                  function() Snacks.picker.buffers() end
                ''
                {
                  desc = "[,] Buffers";
                  lua = true;
                }
              )
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
              (mkKeymap [ "n" "v" ] "<leader>."
                # lua
                ''
                  function() Snacks.picker.resume() end
                ''
                {
                  desc = "[.] Resume";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>:"
                # lua
                ''
                  function() Snacks.picker.command_history() end
                ''
                {
                  desc = "[:] Command History";
                  lua = true;
                }
              )

              # files
              (mkKeymap [ "n" "v" ] "<leader>fb"
                # lua
                ''
                  function() Snacks.git.buffers() end
                ''
                {
                  desc = "[F]ind [B]uffers";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>fc"
                # lua
                ''
                  function() Snacks.git.files({ cwd = vim.fn.stdpath("config") }) end
                ''
                {
                  desc = "[F]ind [C]onfig";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>ff"
                # lua
                ''
                  function() Snacks.git.files() end
                ''
                {
                  desc = "[F]ind [F]iles";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>fi"
                # lua
                ''
                  function() Snacks.git.files({ cwd = "$HOME/Code/infra" }) end
                ''
                {
                  desc = "[F]ind [I]nfra";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>fg"
                # lua
                ''
                  function() Snacks.git.git_files() end
                ''
                {
                  desc = "[F]ind [G]it Files";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>fr"
                # lua
                ''
                  function() Snacks.git.recent() end
                ''
                {
                  desc = "[F]ind [R]ecent";
                  lua = true;
                }
              )

              # git
              (mkKeymap [ "n" "v" ] "<leader>gb"
                # lua
                ''
                  function() Snacks.git.blame_line() end
                ''
                {
                  desc = "[G]it [B]lame";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>gB"
                # lua
                ''
                  function() Snacks.gitbrowse() end
                ''
                {
                  desc = "[G]it [B]rowse";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>gc"
                # lua
                ''
                  function() Snacks.lazygit.git_log() end
                ''
                {
                  desc = "[G]it [C]ommits";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>gf"
                # lua
                ''
                  function() Snacks.lazygit.logfile() end
                ''
                {
                  desc = "[G]it [F]ile Log";
                  lua = true;
                }
              )
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
              (mkKeymap [ "n" "v" ] "<leader>gl"
                # lua
                ''
                  function() Snacks.lazygit.log() end
                ''
                {
                  desc = "[G]it [L]og (cwd)";
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

              # search
              (mkKeymap [ "n" "v" ] "<leader>sb"
                # lua
                ''
                  function() Snacks.picker.lines() end
                ''
                {
                  desc = "[S]earch [B]uffer Lines";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sB"
                # lua
                ''
                  function() Snacks.picker.grep_buffers() end
                ''
                {
                  desc = "[S]earch Open [B]uffer (grep)";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sg"
                # lua
                ''
                  function() Snacks.picker.grep() end
                ''
                {
                  desc = "[S]earch [G]rep";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sw"
                # lua
                ''
                  function() Snacks.picker.lines() end
                ''
                {
                  desc = "[S]earch [W]ord (grep)";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>s\""
                # lua
                ''
                  function() Snacks.picker.registers() end
                ''
                {
                  desc = "[S]earch [R]egisters";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sa"
                # lua
                ''
                  function() Snacks.picker.autocmds() end
                ''
                {
                  desc = "[S]earch [A]utocmds";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sc"
                # lua
                ''
                  function() Snacks.picker.command_history() end
                ''
                {
                  desc = "[S]earch [C]ommand History";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sC"
                # lua
                ''
                  function() Snacks.picker.commands() end
                ''
                {
                  desc = "[S]earch [C]ommands";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sd"
                # lua
                ''
                  function() Snacks.picker.diagnostics_buffer() end
                ''
                {
                  desc = "[S]earch [D]iagnostics (buffer)";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sD"
                # lua
                ''
                  function() Snacks.picker.diagnostics() end
                ''
                {
                  desc = "[S]earch [D]iagnostics";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sh"
                # lua
                ''
                  function() Snacks.picker.help() end
                ''
                {
                  desc = "[S]earch [H]elp";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sH"
                # lua
                ''
                  function() Snacks.picker.highlights() end
                ''
                {
                  desc = "[S]earch [H]ighlights";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sj"
                # lua
                ''
                  function() Snacks.picker.jumps() end
                ''
                {
                  desc = "[S]earch [J]umps";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sk"
                # lua
                ''
                  function() Snacks.picker.keymaps() end
                ''
                {
                  desc = "[S]earch [K]eymaps";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sl"
                # lua
                ''
                  function() Snacks.picker.loclist() end
                ''
                {
                  desc = "[S]earch [L]ocations";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sm"
                # lua
                ''
                  function() Snacks.picker.marks() end
                ''
                {
                  desc = "[S]earch [M]arks";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sM"
                # lua
                ''
                  function() Snacks.picker.man() end
                ''
                {
                  desc = "[S]earch [M]anpages";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sR"
                # lua
                ''
                  function() Snacks.picker.resume() end
                ''
                {
                  desc = "[S]earch [R]esume";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sq"
                # lua
                ''
                  function() Snacks.picker.qflist() end
                ''
                {
                  desc = "[S]earch [Q]uickfix";
                  lua = true;
                }
              )
              (mkKeymap [ "n" "v" ] "<leader>sp"
                # lua
                ''
                  function() Snacks.picker.projects() end
                ''
                {
                  desc = "[S]earch [P]rojects";
                  lua = true;
                }
              )
            ];
        };
      };
    };
  };
}
