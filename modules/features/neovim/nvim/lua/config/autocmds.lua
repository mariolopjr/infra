local group = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  group = group("highlight-yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Treesitter highlighting where a parser is installed",
  group = group("treesitter"),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- ghostty opens new splits and tabs in the directory reported via OSC 7
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  desc = "Emit OSC 7 with the current working directory",
  group = group("osc7-cwd"),
  callback = function()
    local cwd = vim.uv.cwd()
    if not cwd then
      return
    end
    local path = cwd:gsub("([^%w/._~-])", function(c)
      return ("%%%02X"):format(c:byte())
    end)
    io.write(
      ("\027]7;file://%s%s\027\\"):format(vim.uv.os_gethostname() or "", path)
    )
    io.flush()
  end,
})

-- Starting nvim inside a project already has its devenv on PATH (direnv);
-- :cd into another project loads that one's.
vim.api.nvim_create_autocmd("DirChanged", {
  desc = "Load the new directory's direnv environment",
  group = group("direnv"),
  callback = function()
    if vim.fn.executable("direnv") == 0 then
      return
    end
    vim.system({ "direnv", "export", "json" }, { text = true }, function(r)
      if r.code ~= 0 or r.stdout == "" then
        return
      end
      vim.schedule(function()
        for k, v in pairs(vim.json.decode(r.stdout)) do
          vim.env[k] = v ~= vim.NIL and v or nil
        end
      end)
    end)
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  desc = "Autosave modified buffers",
  group = group("autosave"),
  callback = function()
    if
      vim.bo.modified
      and not vim.bo.readonly
      and vim.bo.buftype == ""
      and vim.fn.expand("%") ~= ""
    then
      vim.cmd("silent! update")
    end
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  desc = "Equalize splits when the terminal is resized",
  group = group("resize-splits"),
  command = "tabdo wincmd =",
})
