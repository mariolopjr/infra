-- Dashboard footer like lazy.nvim's: plugin count and startup time.
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
  -- every plugin is a start package from nix, so all of them are loaded
  local plugins = #vim.api.nvim_get_runtime_file("pack/*/start/*", true)
  return {
    align = "center",
    text = {
      { "⚡ Neovim loaded ", hl = "footer" },
      { tostring(plugins), hl = "special" },
      { " plugins in ", hl = "footer" },
      { ("%.2fms"):format(startup_ms()), hl = "special" },
    },
  }
end
