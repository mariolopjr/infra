{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        mini = {
          ai.enable = true;
          ai.setupOpts = {
            n_lines = 500;
          };

          comment.enable = true;
          diff.enable = true;
          hipatterns.enable = true;
          icons.enable = true;
          pairs.enable = true;

          sessions.enable = true;
          sessions.setupOpts = {
            autoread = false;
            autowrite = false;
            file = ".session.nvim";
          };

          snippets.enable = true;
          statusline.enable = true;
          surround.enable = true;
        };

        luaConfigRC.mini-autocommand =
          #lua
          ''
            -- auto-save session on exit
            local sessions = require("mini.sessions")
            vim.api.nvim_create_autocmd("VimLeavePre", {
              callback = function()
                sessions.write(sessions.config.file)
              end,
            })

            -- auto-load session on startup if it exists
            vim.api.nvim_create_autocmd("VimEnter", {
              callback = function()
                local session_file = vim.fn.getcwd() .. sessions.config.file
                if vim.fn.filereadable(session_file) == 1 then
                  sessions.read(sessions.config.file)
                end
              end,
            })
          '';
      };
    };
  };
}
