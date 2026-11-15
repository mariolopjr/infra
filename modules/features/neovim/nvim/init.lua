-- leader keys must be set before plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

require("config.options")
require("config.plugins")
require("config.lsp")
require("config.keymaps")
require("config.autocmds")
