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

-- char mode also labels f/F/t/T targets
require("flash").setup({ modes = { char = { jump_labels = true } } })

require("smart-splits").setup({ move = { at_edge = "stop" } })
