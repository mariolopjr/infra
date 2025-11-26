{ ... }:
let
  wkGroup = lhs: group: {
    "@1" = lhs;
    inherit group;
    mode = [
      "n"
      "v"
    ];
  };
in
{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        binds.whichKey = {
          enable = true;

          setupOpts = {
            preset = "helix";
            spec = [
              (wkGroup "<leader>f" "[F]iles")
              #    {
              #        { "<Tab>", proxy = "<C-w>", group = "windows" },
              #        { "gr", group = "lsp", icon = { icon = "", color = "orange" } },
              #        { "grf", vim.lsp.buf.format, desc = "vim.lsp.buf.format()" },
              #        { "grd", vim.lsp.buf.definition, desc = "vim.lsp.buf.definition()" },
              #        { "grn", vim.lsp.buf.rename, desc = "vim.lsp.buf.rename()" }
              #    }
            ];
          };
        };
      };
    };
  };
}
