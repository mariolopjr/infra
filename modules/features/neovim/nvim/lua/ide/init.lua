-- IDE layer, linked by the dev aspect only (plugins in pack/nix-ide): formatters, language servers and their tooling

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

require("ide.lsp")

vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "[C]ode [F]ormat" })
