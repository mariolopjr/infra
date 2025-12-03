{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        autocomplete.blink-cmp = {
          enable = true;

          friendly-snippets.enable = true;

          setupOpts = {
            keymap.preset = "default";
            signature.enabled = true;
          };
        };
      };
    };
  };
}
