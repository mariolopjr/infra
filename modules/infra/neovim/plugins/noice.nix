{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        ui.noice = {
          enable = true;
          setupOpts = {
            presets = {
              bottom_search = true;
              command_palette = true;
              long_message_to_split = true;
              inc_rename = false;
              lsp_doc_border = false;
            };
          };
        };
      };
    };
  };
}
