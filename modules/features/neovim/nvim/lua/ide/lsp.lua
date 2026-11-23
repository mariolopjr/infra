-- Servers come from each project's devenv
local icons = {
  [vim.diagnostic.severity.ERROR] = "",
  [vim.diagnostic.severity.WARN] = "",
  [vim.diagnostic.severity.HINT] = "",
  [vim.diagnostic.severity.INFO] = "",
}

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded" },
  signs = { text = icons },
  virtual_text = {
    prefix = function(d)
      return icons[d.severity] or "●"
    end,
    spacing = 4,
    source = "if_many",
  },
})

vim.lsp.enable({
  "bashls",
  "gopls",
  "jsonls",
  "just",
  "lua_ls",
  "marksman",
  "nixd",
  "rust_analyzer",
  "taplo",
  "yamlls",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    local supports = getmetatable(client).supports_method
    client.supports_method = function(first, ...)
      if first == client then
        return supports(client, ...)
      end
      return supports(client, first, ...)
    end
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        convert = function(item)
          local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or ""
          local icon = require("mini.icons").get("lsp", kind)
          return { kind = icon .. " " .. kind }
        end,
      })
    end
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})
