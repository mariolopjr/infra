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

                actions = {
                  "flash" =
                    #lua
                    ''
                      function(picker)
                        require("flash").jump({
                          pattern = "^",
                          label = { after = { 0, 0 } },
                          search = {
                            mode = "search",
                            exclude = {
                              function(win)
                                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                              end,
                            },
                          },
                          action = function(match)
                            local idx = picker.list:row2idx(match.pos[1])
                            picker.list:_move(idx, true, true)
                          end,
                        })
                      end,
                    '';
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
                  "<a-s>" = {
                    "@1" = "flash";
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

          luaConfigRC.getRootDir =
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

          keymaps = [
            # general
            (mkKeymap [ "n" "v" ] "<leader>,"
              # lua
              ''
                function() Snacks.picker.buffers() end
              ''
              {
                desc = "buffers";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>/"
              # lua
              ''
                function() Snacks.picker.grep() end
              ''
              {
                desc = "grep";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>."
              # lua
              ''
                function() Snacks.picker.resume() end
              ''
              {
                desc = "resume search";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>:"
              # lua
              ''
                function() Snacks.picker.command_history() end
              ''
              {
                desc = "command history";
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
                desc = "find buffers";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>fc"
              # lua
              ''
                function() Snacks.git.files({ cwd = vim.fn.stdpath("config") }) end
              ''
              {
                desc = "find config";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>ff"
              # lua
              ''
                function() Snacks.git.files() end
              ''
              {
                desc = "find files";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>fi"
              # lua
              ''
                function() Snacks.git.files({ cwd = "$HOME/Code/infra" }) end
              ''
              {
                desc = "find infra";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>fg"
              # lua
              ''
                function() Snacks.git.git_files() end
              ''
              {
                desc = "find git files";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>fr"
              # lua
              ''
                function() Snacks.git.recent() end
              ''
              {
                desc = "find recent";
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
                desc = "git blame";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>gB"
              # lua
              ''
                function() Snacks.gitbrowse() end
              ''
              {
                desc = "git browse";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>gc"
              # lua
              ''
                function() Snacks.lazygit.git_log() end
              ''
              {
                desc = "git commits";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>gf"
              # lua
              ''
                function() Snacks.lazygit.logfile() end
              ''
              {
                desc = "git Logfile";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>gg"
              # lua
              ''
                function() Snacks.lazygit() end
              ''
              {
                desc = "lazygit";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>gl"
              # lua
              ''
                function() Snacks.lazygit.log() end
              ''
              {
                desc = "git log (cwd)";
                lua = true;
              }
            )

            # file explorer
            (mkKeymap [ "n" "v" ] "<leader>fe"
              # lua
              ''
                function()
                  Snacks.explorer({ cwd = get_root_dir() })
                end
              ''
              {
                desc = "file explorer (root dir)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>e"
              # lua
              ''
                function()
                  Snacks.explorer({ cwd = get_root_dir() })
                end
              ''
              {
                desc = "file explorer (root dir)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>fE"
              # lua
              ''
                function() Snacks.explorer() end
              ''
              {
                desc = "file explorer (cwd)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>E"
              # lua
              ''
                function() Snacks.explorer() end
              ''
              {
                desc = "file explorer (cwd)";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>ff"
              # lua
              ''
                function() Snacks.picker.files() end
              ''
              {
                desc = "find file";
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
                desc = "goto definitions";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "gr"
              # lua
              ''
                function() Snacks.picker.lsp_references() end
              ''
              {
                desc = "goto references";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "gI"
              # lua
              ''
                function() Snacks.picker.lsp_implementations() end
              ''
              {
                desc = "goto implementation";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "gy"
              # lua
              ''
                function() Snacks.picker.lsp_type_definitions() end
              ''
              {
                desc = "goto type definition";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>ss"
              # lua
              ''
                function() Snacks.picker.lsp_symbols() end
              ''
              {
                desc = "search symbols";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sS"
              # lua
              ''
                function() Snacks.picker.lsp_references() end
              ''
              {
                desc = "search references";
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
                desc = "search buffer lines";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sB"
              # lua
              ''
                function() Snacks.picker.grep_buffers() end
              ''
              {
                desc = "grep open buffer";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sg"
              # lua
              ''
                function() Snacks.picker.grep() end
              ''
              {
                desc = "grep search";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sw"
              # lua
              ''
                function() Snacks.picker.lines() end
              ''
              {
                desc = "grep search words";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>s\""
              # lua
              ''
                function() Snacks.picker.registers() end
              ''
              {
                desc = "search registers";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sa"
              # lua
              ''
                function() Snacks.picker.autocmds() end
              ''
              {
                desc = "search autocmds";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sc"
              # lua
              ''
                function() Snacks.picker.command_history() end
              ''
              {
                desc = "search command history";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sC"
              # lua
              ''
                function() Snacks.picker.commands() end
              ''
              {
                desc = "search commands";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sd"
              # lua
              ''
                function() Snacks.picker.diagnostics_buffer() end
              ''
              {
                desc = "search diagnostics in buffer";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sD"
              # lua
              ''
                function() Snacks.picker.diagnostics() end
              ''
              {
                desc = "search all diagnostics";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sh"
              # lua
              ''
                function() Snacks.picker.help() end
              ''
              {
                desc = "search help";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sH"
              # lua
              ''
                function() Snacks.picker.highlights() end
              ''
              {
                desc = "search highlights";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sj"
              # lua
              ''
                function() Snacks.picker.jumps() end
              ''
              {
                desc = "search jumps";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sk"
              # lua
              ''
                function() Snacks.picker.keymaps() end
              ''
              {
                desc = "search keymaps";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sl"
              # lua
              ''
                function() Snacks.picker.loclist() end
              ''
              {
                desc = "search locations";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sm"
              # lua
              ''
                function() Snacks.picker.marks() end
              ''
              {
                desc = "search marks";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sM"
              # lua
              ''
                function() Snacks.picker.man() end
              ''
              {
                desc = "search manpages";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sR"
              # lua
              ''
                function() Snacks.picker.resume() end
              ''
              {
                desc = "resume last search";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sq"
              # lua
              ''
                function() Snacks.picker.qflist() end
              ''
              {
                desc = "search quickfix list";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sp"
              # lua
              ''
                function() Snacks.picker.projects() end
              ''
              {
                desc = "search projects";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>st"
              # lua
              ''
                function() Snacks.picker.todo_comments() end
              ''
              {
                desc = "search todos";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader>sT"
              # lua
              ''
                function()
                  Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
                end
              ''
              {
                desc = "search todos/fix/fixme";
                lua = true;
              }
            )
          ];
        };
      };
    };
  };
}
