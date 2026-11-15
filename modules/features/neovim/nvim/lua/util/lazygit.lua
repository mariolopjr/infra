--- Opening files from the lazygit float
local M = {}

--- Hide every visible lazygit float without killing its job
local function hide()
  for _, term in ipairs(Snacks.terminal.list()) do
    local info = vim.b[term.buf].snacks_terminal
    local cmd = info and info.cmd or {}
    cmd = type(cmd) == "table" and cmd or { cmd }
    if cmd[1] == "lazygit" and term:valid() then
      term:hide()
    end
  end
end

--- Open a file from lazygit in the window the float was covering
---@param file string relative to lazygit's cwd
---@param line? integer
---@return string empty because --remote-expr prints whatever is returned
function M.edit(file, line)
  vim.schedule(function()
    hide()
    vim.cmd.edit(vim.fn.fnameescape(file))
    if line then
      pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    end
  end)
  return ""
end

return M
