-- leader keys must be set before plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

require("config.options")
require("config.plugins")
-- lua/ide is linked on hosts with the dev aspect only
if vim.api.nvim_get_runtime_file("lua/ide/init.lua", false)[1] then
  require("ide")
end
require("config.keymaps")
require("config.autocmds")
