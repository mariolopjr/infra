-- run via `just test-nvim`; the recipe sets SSH_TTY or REX_BLOCK per run
local cb = vim.g.clipboard
assert(
  type(cb) == "table" and cb.name == "OSC 52",
  "over SSH or in a rex pane, g:clipboard should be OSC 52, got "
    .. vim.inspect(cb)
)
assert(
  vim.fn["provider#clipboard#Executable"]() == "OSC 52",
  "clipboard provider did not resolve to OSC 52"
)

vim.fn.setreg("", "hello", "v")
local got = cb.paste["+"]()
assert(
  got[1][1] == "hello" and got[2] == "v",
  "paste should read the unnamed register, got " .. vim.inspect(got)
)
print("ok")
