{ inputs, ... }:
let
  inherit (inputs.nvf) lib;
  inherit (lib.nvim.binds) mkKeymap;
in
{
  infra.neovim = _: {
    homeManager =
      { pkgs, ... }:
      {
        programs.nvf = {
          settings.vim = {
            extraPlugins = {
              persistence = {
                package = pkgs.vimPlugins.persistence-nvim;
                setup =
                  #lua
                  ''
                    require("persistence").setup({
                      dir = vim.fn.stdpath("state") .. "/sessions/",
                      need = 1,
                      branch = true,
                    })

                    -- Directories where sessions should not be saved or restored
                    local home = vim.fn.expand("~")
                    local disabled_dirs = {
                      home,
                      home .. "/Downloads",
                      home .. "/Desktop",
                      "/",
                      "/tmp",
                    }

                    local group = vim.api.nvim_create_augroup("Persistence", { clear = true })

                    -- Autosave session on exit
                    -- vim.api.nvim_create_autocmd("VimLeavePre", {
                    --   group = group,
                    --   callback = function()
                    --     local cwd = vim.fn.getcwd()
                    --     for _, path in pairs(disabled_dirs) do
                    --       if path == cwd then
                    --         return
                    --       end
                    --     end
                    --     require("persistence").save()
                    --   end,
                    -- })

                    -- Auto-restore session when entering vim without arguments
                    -- vim.api.nvim_create_autocmd("VimEnter", {
                    --   group = group,
                    --   callback = function()
                    --     local cwd = vim.fn.getcwd()
                    --
                    --     for _, path in pairs(disabled_dirs) do
                    --       if path == cwd then
                    --         require("persistence").stop()
                    --         return
                    --       end
                    --     end
                    --
                    --     if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
                    --       require("persistence").load()
                    --     else
                    --       require("persistence").stop()
                    --     end
                    --   end,
                    --   nested = true,
                    -- })
                  '';
              };
            };
            keymaps = [
              (mkKeymap [ "n" ] "<leader>qs"
                # lua
                ''
                  function() require("persistence").save() end
                ''
                {
                  desc = "save session";
                  lua = true;
                }
              )
              (mkKeymap [ "n" ] "<leader>qS"
                # lua
                ''
                  function() require("persistence").select() end
                ''
                {
                  desc = "select session";
                  lua = true;
                }
              )
              (mkKeymap [ "n" ] "<leader>ql"
                # lua
                ''
                  function() require("persistence").load() end
                ''
                {
                  desc = "load session";
                  lua = true;
                }
              )
              (mkKeymap [ "n" ] "<leader>qL"
                # lua
                ''
                  function() require("persistence").load({ last = "true" }) end
                ''
                {
                  desc = "load last session";
                  lua = true;
                }
              )
              (mkKeymap [ "n" ] "<leader>qd"
                # lua
                ''
                  function() require("persistence").stop() end
                ''
                {
                  desc = "do not save current session";
                  lua = true;
                }
              )
            ];
          };
        };
      };
  };
}
