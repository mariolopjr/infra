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

            # force .h files to c
            c_syntax_for_h = true;
          };

          options = {
            number = true;
            relativenumber = true;
            mouse = "a";
            showmode = false;
            cursorline = true;
            termguicolors = true;

            clipboard = "unnamedplus";

            modeline = true;
            breakindent = true;
            undofile = true;

            ignorecase = true;
            smartcase = true;

            signcolumn = "yes";

            # time taken to write to swap in ms when no typing occurs
            updatetime = 500;

            timeoutlen = 400;
            ttimeoutlen = 10;

            # splits
            splitright = true;
            splitbelow = true;

            list = true;
            listchars = "tab:» ,trail:·,nbsp:␣";

            inccommand = "split";

            # minimal number of screen lines to keep above and below the cursor.
            scrolloff = 10;

            # treesitter folding
            foldmethod = "expr";
            foldexpr = "nvim_treesitter#foldexpr()";
            foldcolumn = "0";
            foldtext = ""; # first line of fold will have syntax highlighting
            foldlevel = 5; # ensure file is unfolded
            foldnestmax = 4; # only fold up to 4 levels deep

            # set tabs to 4 spaces by default
            tabstop = 4;
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
            zig.enable = true;
          };
          lsp = {
            enable = true;
            formatOnSave = true;
          };
          treesitter.enable = true;

          luaConfigRC.diagnosticGoto =
            #lua
            ''
              local diagnostic_goto = function(next, severity)
                return function()
                  vim.diagnostic.jump({
                    count = (next and 1 or -1) * vim.v.count1,
                    severity = severity and vim.diagnostic.severity[severity] or nil,
                    float = true,
                  })
                end
              end
            '';

          keymaps = [
            (mkKeymap [ "n" "v" ] "<Esc>" "<cmd>nohlsearch<CR>" { })

            (mkKeymap [ "n" "v" ] "<left>" "<cmd>echo \"Use h to move!!\"<CR>" { })
            (mkKeymap [ "n" "v" ] "<right>" "<cmd>echo \"Use l to move!!\"<CR>" { })
            (mkKeymap [ "n" "v" ] "<up>" "<cmd>echo \"Use k to move!!\"<CR>" { })
            (mkKeymap [ "n" "v" ] "<down>" "<cmd>echo \"Use j to move!!\"<CR>" { })

            (mkKeymap "n" "go" "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>" {
              desc = "Add line after no insert";
            })
            (mkKeymap "n" "gO" "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>" {
              desc = "Add line before no insert";
            })

            (mkKeymap "n" "<leader>fn" "<cmd>enew<CR>" { desc = "new file"; })
            (mkKeymap [ "n" "v" ] "<leader>fs" ":w<CR>" {
              desc = "save file";
            })
            (mkKeymap [ "n" "v" ] "<leader>fq" ":q<CR>" {
              desc = "close file";
            })
            (mkKeymap [ "n" "v" ] "<leader>q" ":cquit<CR>" {
              desc = "quit";
              noremap = true;
              silent = true;
            })

            (mkKeymap "n" "[q" "<cmd>vim.cmd.cprev<CR>" { desc = "previous quickfix"; })
            (mkKeymap "n" "]q" "<cmd>vim.cmd.cnext<CR>" { desc = "next quickfix"; })
            (mkKeymap "n" "[d"
              #lua
              ''
                diagnostic_goto(false)
              ''
              {
                desc = "previous quickfix";
                lua = true;
              }
            )
            (mkKeymap "n" "]d"
              #lua
              ''
                diagnostic_goto(true)
              ''
              {
                desc = "next quickfix";
                lua = true;
              }
            )
            (mkKeymap "n" "[e"
              #lua
              ''
                diagnostic_goto(false, "ERROR")
              ''
              {
                desc = "previous error";
                lua = true;
              }
            )
            (mkKeymap "n" "]e"
              #lua
              ''
                diagnostic_goto(true, "ERROR")
              ''
              {
                desc = "next error";
                lua = true;
              }
            )
            (mkKeymap "n" "[w"
              #lua
              ''
                diagnostic_goto(false, "WARN")
              ''
              {
                desc = "previous warning";
                lua = true;
              }
            )
            (mkKeymap "n" "]w"
              #lua
              ''
                diagnostic_goto(true, "WARN")
              ''
              {
                desc = "next warning";
                lua = true;
              }
            )
          ];
        };
      };
    };
  };
}
