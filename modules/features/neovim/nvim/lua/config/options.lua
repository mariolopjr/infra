vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.showmode = false -- mini.statusline shows it
vim.o.cursorline = true

-- over SSH or in a rex pane: copy via OSC 52, paste from the unnamed register
-- (rex panes have no WAYLAND_DISPLAY/SSH_TTY; rex relays OSC 52 to its client.
-- OSC 52 paste would hit the terminal's clipboard-read prompt on every `p`)
if vim.env.SSH_TTY or vim.env.REX_BLOCK then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- defer clipboard sync
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300 -- which-key pops up sooner
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.scrolloff = 10
vim.o.tabstop = 4
vim.o.winborder = "rounded"

vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldtext = "" -- first line of a fold keeps its highlighting
vim.o.foldlevel = 99

vim.o.autocomplete = true
vim.o.complete = "o" -- LSP only autocomplete
vim.o.completeopt = "menuone,noselect,popup,fuzzy"
vim.o.pumborder = "rounded"
