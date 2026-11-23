-- run by checks.neovim-shared: the shared config with only the nixpkgs plugins, no IDE layer
for _, mod in ipairs({
  "catppuccin",
  "mini.statusline",
  "snacks",
  "which-key",
  "flash",
  "smart-splits",
}) do
  assert(package.loaded[mod], mod .. " was not set up")
end
assert(not package.loaded.conform, "the IDE layer loaded without lua/ide")

local function mapped(mode, lhs)
  return not vim.tbl_isempty(vim.fn.maparg(lhs, mode, false, true))
end
assert(mapped("n", "s"), "flash jump not mapped")
assert(mapped("n", "<C-h>"), "smart-splits move not mapped")
assert(mapped("n", " ff"), "snacks file picker not mapped")
assert(mapped("n", " e"), "snacks explorer not mapped")
assert(not mapped("n", " cf"), "conform format mapped without the IDE layer")
assert(vim.v.errmsg == "", "startup error: " .. vim.v.errmsg)
print("ok")
