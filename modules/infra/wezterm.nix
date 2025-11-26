{
  infra.wezterm = _: {
    homeManager = {
      programs.wezterm = {
        enable = true;

        extraConfig =
          # lua
          ''
            ---@type Wezterm
            local wezterm = require("wezterm")
            local action = wezterm.action
            local config = wezterm.config_builder()

            config.term = "wezterm"
            config.animation_fps = 144
            config.max_fps = 144
            config.front_end = "WebGpu"

            -- set theme settings
            config.color_scheme = "Catppuccin Macchiato"
            config.font = wezterm.font "JetBrains Mono"
            config.font_size = 13

            -- tab bar config
            config.hide_tab_bar_if_only_one_tab = true
            config.use_fancy_tab_bar = false
            config.tab_bar_at_bottom = true
            config.tab_max_width = 30

            -- keymaps
            local function is_nvim(pane)
              -- this is set by the plugin, and unset on ExitPre in Neovim
              return pane:get_user_vars().IS_NVIM == "true"
            end

            local function find_nvim_pane(tab)
              for _, pane in ipairs(tab:panes()) do
                if is_nvim(pane) then
                  return pane
                end
              end
            end

            local direction_keys = {
              h = "Left",
              j = "Down",
              k = "Up",
              l = "Right",
            }

            local function split_nav(resize_or_move, key)
              return {
                key = key,
                mods = resize_or_move == "resize" and "META" or "CTRL",
                action = wezterm.action_callback(function(win, pane)
                  if is_nvim(pane) then
                    -- pass the keys through to nvim
                    win:perform_action({
                      SendKey = {
                        key = key,
                        mods = resize_or_move == "resize" and "META" or "CTRL",
                      },
                    }, pane)
                  else
                    if resize_or_move == "resize" then
                      win:perform_action(
                        { AdjustPaneSize = { direction_keys[key], 3 } },
                        pane
                      )
                    else
                      win:perform_action(
                        { ActivatePaneDirection = direction_keys[key] },
                        pane
                      )
                    end
                  end
                end),
              }
            end

            config.leader = { key = ",", mods = "CTRL", timeout_milliseconds = 2000 }
            config.keys = {
              -- move between split panes
              split_nav("move", "h"),
              split_nav("move", "j"),
              split_nav("move", "k"),
              split_nav("move", "l"),

              -- resize panes
              split_nav("resize", "h"),
              split_nav("resize", "j"),
              split_nav("resize", "k"),
              split_nav("resize", "l"),

              -- split panes
              {
                key = "-",
                mods = "CTRL",
                action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
              },
              {
                key = "\\",
                mods = "CTRL",
                action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
              },
              -- will use a key table for this instead
              -- {
              --   key = "w",
              --   mods = "CTRL",
              --   action = wezterm.action_callback(function(window, pane)
              --     if is_nvim(pane) then
              --       -- pass the keys through to nvim
              --       window:perform_action({
              --         SendKey = { key = "w", mods = "CTRL" },
              --       }, pane)
              --     else
              --       action.CloseCurrentPane({ confirm = false })
              --     end
              --   end),
              -- },
              {
                key = ";",
                mods = "CTRL",
                action = wezterm.action_callback(function(window, pane)
                  local tab = window:active_tab()

                  -- Open pane below if current pane is nvim
                  if is_nvim(pane) then
                    if (#tab:panes()) == 1 then
                      -- Open pane below if when there is only one pane and it is nvim
                      pane:split({ direction = "Bottom" })
                      -- else
                      --   -- Send `CTRL-; to vim`, navigate to bottom pane from nvim
                      --   window:perform_action({
                      --     SendKey = { key = ";", mods = "CTRL" },
                      --   }, pane)
                    end
                    return
                  end

                  -- Zoom to nvim pane if it exists
                  local nvim_pane = find_nvim_pane(tab)
                  if nvim_pane then
                    nvim_pane:activate()
                    tab:set_zoomed(true)
                  end
                end),
              },

              -- remap clear viewport
              {
                key = "k",
                mods = "SUPER",
                action = action.Multiple({
                  action.ClearScrollback("ScrollbackAndViewport"),
                  action.SendKey({ key = "L", mods = "CTRL" }),
                }),
              },
            }
            return config
          '';
      };
    };
  };
}
