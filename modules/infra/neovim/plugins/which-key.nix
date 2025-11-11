{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        binds.whichKey = {
          enable = true;

          setupOpts = {
            preset = "helix";
            #spec = lib.mkLuaInline ''
            #    {
            #        { "<Tab>", proxy = "<C-w>", group = "windows" },
            #        { "gr", group = "lsp", icon = { icon = "", color = "orange" } },
            #        { "grf", vim.lsp.buf.format, desc = "vim.lsp.buf.format()" },
            #        { "grd", vim.lsp.buf.definition, desc = "vim.lsp.buf.definition()" },
            #        { "grn", vim.lsp.buf.rename, desc = "vim.lsp.buf.rename()" }
            #    }
            #'';
          };
        };
      };
    };
  };
}
