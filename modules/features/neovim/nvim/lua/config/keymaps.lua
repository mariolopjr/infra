local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- splits
local splits = require("smart-splits")
map("n", "<C-h>", splits.move_cursor_left)
map("n", "<C-j>", splits.move_cursor_down)
map("n", "<C-k>", splits.move_cursor_up)
map("n", "<C-l>", splits.move_cursor_right)
map("n", "<A-h>", splits.resize_left)
map("n", "<A-j>", splits.resize_down)
map("n", "<A-k>", splits.resize_up)
map("n", "<A-l>", splits.resize_right)

-- flash jumps
local flash = require("flash")
map({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash" })
map({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash Treesitter" })
map("o", "r", flash.remote, { desc = "Remote Flash" })
map({ "o", "x" }, "R", flash.treesitter_search, { desc = "Treesitter Search" })
map("c", "<c-s>", flash.toggle, { desc = "Toggle Flash Search" })

-- buffers, files, tabs
map("n", "<leader>bd", "<cmd>bd<CR>", { desc = "[B]uffer [D]elete" })
map("n", "<leader>fs", "<cmd>w<CR>", { desc = "[F]ile [S]ave" })
map("n", "<leader>fq", "<cmd>q<CR>", { desc = "[F]ile [Q]uit" })
map("n", "<leader>q", "<cmd>cquit<CR>", { desc = "[Q]uit Neovim" })
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "[N]ew tab" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "[C]lose tab" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- diagnostics: jump and show the float
local function jump(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", jump(1), { desc = "Next Diagnostic" })
map("n", "[d", jump(-1), { desc = "Prev Diagnostic" })
map("n", "]e", jump(1, "ERROR"), { desc = "Next Error" })
map("n", "[e", jump(-1, "ERROR"), { desc = "Prev Error" })

-- lsp (grn, gra, grr, gri, K and <C-s> are Neovim defaults)
map("n", "gD", vim.lsp.buf.declaration, { desc = "[G]oto [D]eclaration" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "[C]ode [R]ename" })
map(
  { "n", "x" },
  "<leader>ca",
  vim.lsp.buf.code_action,
  { desc = "[C]ode [A]ction" }
)
map("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "[C]ode [F]ormat" })
map("n", "<leader>ch", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "[C]ode Toggle Inlay [H]ints" })
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<CR>", { desc = "LSP [I]nfo" })

-- snacks: pickers, explorer, git, zen
local pick = function(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end
local errors = { severity = vim.diagnostic.severity.ERROR }
-- stylua: ignore start
map("n", "<leader><leader>", pick("files"), { desc = "Find Files" })
map("n", "<leader>,", pick("buffers"), { desc = "Buffers" })
map("n", "<leader>/", pick("grep"), { desc = "Grep" })
map("n", "<leader>:", pick("command_history"), { desc = "Command History" })
map("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>'", pick("resume"), { desc = "Resume Search" })
map("n", "<leader>fb", pick("buffers"), { desc = "Buffers" })
map("n", "<leader>fc", pick("files", { cwd = vim.fn.stdpath("config") }), { desc = "Find Config File" })
map("n", "<leader>ff", pick("files"), { desc = "Find Files" })
map("n", "<leader>fg", pick("git_files"), { desc = "Find Git Files" })
map("n", "<leader>fr", pick("recent"), { desc = "Recent" })
map("n", "<leader>sb", pick("lines"), { desc = "Buffer Lines" })
map("n", "<leader>sB", pick("grep_buffers"), { desc = "Grep Open Buffers" })
map("n", "<leader>sg", pick("grep"), { desc = "Grep" })
map({ "n", "x" }, "<leader>sw", pick("grep_word"), { desc = "Grep word or selection" })
map("n", "<leader>s.", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer" })
map("n", '<leader>s"', pick("registers"), { desc = "Registers" })
map("n", "<leader>sa", pick("autocmds"), { desc = "Autocmds" })
map("n", "<leader>sc", pick("command_history"), { desc = "Command History" })
map("n", "<leader>sC", pick("commands"), { desc = "Commands" })
map("n", "<leader>sd", pick("diagnostics_buffer"), { desc = "Diagnostics (Buffer)" })
map("n", "<leader>sD", pick("diagnostics"), { desc = "Diagnostics" })
map("n", "<leader>se", pick("diagnostics_buffer", errors), { desc = "Errors (Buffer)" })
map("n", "<leader>sE", pick("diagnostics", errors), { desc = "Errors (Project)" })
map("n", "<leader>sh", pick("help"), { desc = "Help Pages" })
map("n", "<leader>sH", pick("highlights"), { desc = "Highlights" })
map("n", "<leader>sj", pick("jumps"), { desc = "Jumps" })
map("n", "<leader>sk", pick("keymaps"), { desc = "Keymaps" })
map("n", "<leader>sl", pick("loclist"), { desc = "Location List" })
map("n", "<leader>sm", pick("marks"), { desc = "Marks" })
map("n", "<leader>sM", pick("man"), { desc = "Man Pages" })
map("n", "<leader>sn", pick("notifications"), { desc = "Notification History" })
map("n", "<leader>sN", pick("notifications", { filter = "error" }), { desc = "Notification History (Errors)" })
map("n", "<leader>sp", pick("projects"), { desc = "[S]earch Projects" })
map("n", "<leader>sq", pick("qflist"), { desc = "Quickfix List" })
map("n", "<leader>sR", pick("resume"), { desc = "Resume" })
map("n", "<leader>ss", pick("lsp_symbols"), { desc = "[S]earch [S]ymbols" })
map("n", "<leader>sS", pick("lsp_references"), { desc = "[S]earch References" })
map("n", "<leader>pC", pick("colorschemes"), { desc = "[C]olorschemes" })
map("n", "gd", pick("lsp_definitions"), { desc = "[G]oto [D]efinition" })
map("n", "gr", pick("lsp_references"), { nowait = true, desc = "[G]oto [R]eferences" })
map("n", "gI", pick("lsp_implementations"), { desc = "[G]oto [I]mplementation" })
map("n", "gy", pick("lsp_type_definitions"), { desc = "[G]oto T[y]pe Definition" })
map("n", "<leader>fe", function()
  Snacks.explorer({ cwd = vim.lsp.buf.list_workspace_folders()[1] or Snacks.git.get_root() or vim.fn.getcwd() })
end, { desc = "[F]ile [E]xplorer (root dir)" })
map("n", "<leader>fE", function() Snacks.explorer() end, { desc = "[F]ile [E]xplorer (cwd)" })
map("n", "<leader>e", "<leader>fe", { desc = "[F]ile [E]xplorer (root dir)", remap = true })
map("n", "<leader>E", "<leader>fE", { desc = "[F]ile [E]xplorer (cwd)", remap = true })
map({ "n", "t" }, "<M-g>", function() Snacks.lazygit() end, { desc = "Lazygit" })
map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit" })
map("n", "<leader>gb", function() Snacks.git.blame_line() end, { desc = "[G]it [B]lame" })
map("n", "<leader>gB", function() Snacks.gitbrowse() end, { desc = "[G]it [B]rowse" })
map("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit Current File History" })
map("n", "<leader>gl", function() Snacks.lazygit.log() end, { desc = "Lazygit Log (cwd)" })
map("n", "<leader>gc", pick("git_log"), { desc = "Git Log" })
map("n", "<leader>gs", pick("git_status"), { desc = "Git Status" })
map("n", "<leader>z", function() Snacks.zen.zoom() end, { desc = "[Z]oom (maximize window)" })
map("n", "<leader>Z", function() Snacks.zen() end, { desc = "[Z]en Mode" })
-- stylua: ignore end

-- sessions: .session.nvim in the project dir, written on exit once one exists
map("n", "<leader>Ss", function()
  MiniSessions.write(".session.nvim")
end, { desc = "[S]ave session (this dir)" })
map("n", "<leader>Sl", function()
  MiniSessions.select("read")
end, { desc = "[L]oad session" })
map("n", "<leader>Sd", function()
  MiniSessions.select("delete")
end, { desc = "[D]elete session" })
