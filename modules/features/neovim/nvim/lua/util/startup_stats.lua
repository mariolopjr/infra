-- Dashboard footer like lazy.nvim's: plugin counts from vim.pack and startup time.
local ffi = require("ffi")
ffi.cdef([[
  typedef struct { long tv_sec; long tv_nsec; } timespec_t;
  int clock_gettime(int clock_id, timespec_t *tp);
]])

-- Process CPU time when the dashboard renders, at the end of startup. Includes what runs before init.lua.
local function startup_ms()
  local t = ffi.new("timespec_t")
  ffi.C.clock_gettime(jit.os == "OSX" and 12 or 2, t) -- CLOCK_PROCESS_CPUTIME_ID
  return tonumber(t.tv_sec) * 1e3 + tonumber(t.tv_nsec) / 1e6
end

return function()
  local plugins = vim.pack.get()
  local loaded = #vim.tbl_filter(function(p)
    return p.active
  end, plugins)
  return {
    align = "center",
    text = {
      { "⚡ Neovim loaded ", hl = "footer" },
      { ("%d/%d"):format(loaded, #plugins), hl = "special" },
      { " plugins (", hl = "footer" },
      { tostring(#plugins - loaded), hl = "special" },
      { " lazy) in ", hl = "footer" },
      { ("%.2fms"):format(startup_ms()), hl = "special" },
    },
  }
end
