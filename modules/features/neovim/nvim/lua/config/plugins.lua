vim.pack.add({
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/folke/lazydev.nvim",
  "https://github.com/folke/which-key.nvim",
  {
    src = "https://github.com/smart-splits-nvim/smart-splits.nvim",
    version = vim.version.range("3"),
  },
})

require("catppuccin").setup({
  flavor = "macchiato",
  custom_highlights = function(c)
    return {
      NormalFloat = { bg = c.base },
      FloatBorder = { bg = c.base, fg = c.blue },
      DiagnosticUnnecessary = { fg = c.overlay1 },
    }
  end,
  integrations = { mini = { enabled = true }, snacks = true, which_key = true },
})
vim.cmd.colorscheme("catppuccin-macchiato")

require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()
require("mini.statusline").setup()
require("mini.pairs").setup()
require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup({
  mappings = {
    add = "gsa",
    delete = "gsd",
    find = "gsf",
    find_left = "gsF",
    highlight = "gsh",
    replace = "gsr",
  },
})
require("mini.diff").setup()

local sessions = require("mini.sessions")
sessions.setup({ autoread = false, autowrite = true, file = ".session.nvim" })
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.filereadable(".session.nvim") == 1 then
      sessions.read(".session.nvim")
    end
  end,
})

local exclude = { "*.uid", "*.import" } -- Godot metadata companions
require("snacks").setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    preset = {
      -- stylua: ignore
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      {
        icon = " ",
        title = "Keymaps",
        section = "keys",
        indent = 2,
        padding = 1,
      },
      {
        icon = " ",
        title = "Projects",
        section = "projects",
        limit = 15,
        indent = 2,
        padding = 1,
      },
      require("util.startup_stats"),
    },
  },
  explorer = { replace_netrw = true },
  gitbrowse = {},
  indent = { enabled = true },
  input = { enabled = true },
  lazygit = {
    -- open files in this nvim instead of a nested one, so lazygit is not killed
    config = {
      os = {
        edit = "nvim --server \"$NVIM\" --remote-expr \"v:lua.require'util.lazygit'.edit('{{filename}}')\"",
        editAtLine = "nvim --server \"$NVIM\" --remote-expr \"v:lua.require'util.lazygit'.edit('{{filename}}', {{line}})\"",
      },
    },
  },
  notifier = { enabled = true },
  picker = {
    actions = {
      focus_main = function(picker)
        vim.api.nvim_set_current_win(picker.main)
      end,
      -- builtin yank's notification wraps the value in a markdown code block
      yank = function(_, item)
        if not item then
          return
        end
        local value = item.data or item.text
        local reg = vim.v.register
        vim.fn.setreg(reg, value)
        Snacks.notify(
          ("Yanked to register `%s`: %s"):format(reg, value),
          { title = "Snacks Picker" }
        )
      end,
    },
    sources = {
      explorer = { exclude = exclude },
      files = { exclude = exclude },
      grep = { exclude = exclude },
      -- ledger transactions are Event-kind symbols
      lsp_symbols = { filter = { ledger = true } },
      lsp_workspace_symbols = { filter = { ledger = true } },
      recent = {
        direct = true,
        toggles = { direct = "E" },
        finder = function(opts, ctx)
          if opts.direct then
            return require("util.startup_files").finder(opts, ctx)
          end
          return require("snacks.picker.source.recent").files(opts, ctx)
        end,
        win = {
          input = {
            keys = {
              ["<a-e>"] = {
                "toggle_direct",
                mode = { "i", "n" },
                desc = "Toggle Directly Edited",
              },
            },
          },
          list = { keys = { ["<a-e>"] = "toggle_direct" } },
        },
      },
    },
    win = {
      input = {
        keys = {
          ["<Esc>"] = { "close", mode = { "n", "i" } },
          ["<C-l>"] = { "focus_main", mode = { "n", "i" } },
          -- <A-h> resizes splits everywhere
          ["<a-h>"] = false,
          ["<a-.>"] = { "toggle_hidden", mode = { "i", "n" } },
          -- scroll the preview like lazygit
          ["J"] = { "preview_scroll_down", mode = { "i", "n" } },
          ["K"] = { "preview_scroll_up", mode = { "i", "n" } },
          ["H"] = { "preview_scroll_left", mode = { "i", "n" } },
          ["L"] = { "preview_scroll_right", mode = { "i", "n" } },
          ["<c-y>"] = { "yank", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<a-h>"] = false,
          ["<a-.>"] = "toggle_hidden",
          ["<C-l>"] = "focus_main",
          ["<c-y>"] = "yank",
        },
      },
    },
  },
  quickfile = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = {
    enabled = true,
    git = { patterns = { "GitSign", "MiniDiffSign", "Coverage" } },
  },
  terminal = { enabled = false },
  words = { enabled = true },
})

-- remember files opened as `nvim file` for the recent picker
if vim.v.vim_did_enter == 1 then
  require("util.startup_files").record()
else
  vim.api.nvim_create_autocmd(
    "VimEnter",
    { once = true, callback = require("util.startup_files").record }
  )
end

-- LSP progress in the notifier
local progress = vim.defaulttable()
local spinner =
  { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
vim.api.nvim_create_autocmd("LspProgress", {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    if not client or type(value) ~= "table" then
      return
    end
    local p = progress[client.id]
    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ("[%3d%%] %s%s"):format(
            value.kind == "end" and 100 or value.percentage or 100,
            value.title or "",
            value.message and (" **%s**"):format(value.message) or ""
          ),
          done = value.kind == "end",
        }
        break
      end
    end
    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)
    vim.notify(table.concat(msg, "\n"), "info", {
      id = "lsp_progress",
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and " "
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

-- lua_ls gets the nvim runtime and these plugins' types
require("lazydev").setup({
  library = {
    { path = "snacks.nvim", words = { "Snacks" } },
    { path = "mini.nvim", words = { "Mini%w+" } },
  },
})

require("conform").setup({
  notify_on_error = true,
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
  formatters_by_ft = {
    go = { "goimports", "gofumpt" },
    lua = { "stylua" },
    nix = { "nixfmt" },
    rust = { "rustfmt" },
    sh = { "shfmt" },
  },
})

require("which-key").setup({
  preset = "helix",
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { "<leader>b", group = "[B]uffer" },
    { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
    { "<leader>f", group = "[F]iles" },
    { "<leader>g", group = "[G]it" },
    { "<leader>l", group = "[L]SP" },
    { "<leader>s", group = "[S]earch" },
    { "<leader>S", group = "[S]ession" },
    { "<leader>t", group = "[T]abs" },
  },
})

require("smart-splits").setup({ move = { at_edge = "stop" } })
