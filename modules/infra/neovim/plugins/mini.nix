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

          snippets.enable = true;
          statusline.enable = true;
          surround = {
            enable = true;

            setupOpts = {
              mappings = {
                add = "<leader>ta";
                delete = "<leader>td";
                find = "<leader>tf";
                find_left = "<leader>tF";
                highlight = "<leader>th";
                replace = "<leader>tr";
              };
            };
          };
        };
      };
    };
  };
}
