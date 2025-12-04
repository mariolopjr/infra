{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        utility.motion.flash-nvim = {
          enable = true;

          setupOpts = {
            modes = {
              char = {
                jump_labels = true;
              };
            };
          };
        };
      };
    };
  };
}
