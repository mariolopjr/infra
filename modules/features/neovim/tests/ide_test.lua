-- run by checks.neovim-ide: the shared config plus lua/ide, every plugin from nixpkgs
for _, mod in ipairs({ "snacks", "flash", "conform", "lazydev" }) do
  assert(package.loaded[mod], mod .. " was not set up")
end
assert(
  vim.api.nvim_get_runtime_file("lsp/nixd.lua", false)[1],
  "nvim-lspconfig server configs not on the runtimepath"
)
assert(
  not vim.tbl_isempty(vim.fn.maparg(" cf", "n", false, true)),
  "conform format not mapped"
)
assert(vim.v.errmsg == "", "startup error: " .. vim.v.errmsg)
print("ok")
