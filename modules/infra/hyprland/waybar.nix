{
  infra.hyprland = _: {
    homeManager = {
      # credit to bibjaw99/workstation: https://github.com/bibjaw99/workstation/tree/master/config_dotfiles/config/waybar_configs
      programs.waybar = {
        enable = true;
        settings = {
          waybar = {
            layer = "top";
            position = "top";

            height = 40;
            spacing = 5;

            margin-top = 5;
            margin-left = 5;
            margin-right = 5;

            modules-left = [
              "custom/nixos"
              "hyprland/workspaces"
              "hyprland/window"
              "tray"
              "hyprland/submap"
            ];

            modules-center = [
              "clock"
            ];

            modules-right = [
              "network"
              "disk"
              "cpu"
              "temperature"
              "memory"
              #"custom/cpu_temp"
              #"backlight"
              #"custom/memory"
              "pulseaudio"
              "battery"
              "idle_inhibitor"
            ];

            # tweak scripts
            "custom/nixos" = {
              format = "";
              on-click = "rofi -show drun -disable-history -show-icons";
              #on-click-right = "~/.config/custom_scripts/power.sh";
              escape = true;
              tooltip = true;
              tooltip-format = "nixos";
            };

            "hyprland/workspaces" = {
              disable-scroll = true;
              active-only = false;
              all-outputs = true;
              warp-on-scroll = false;
              format = "{icon}";
              format-icons = {
                "1" = "<span>󰈹</span>";
                "2" = "<span></span>";
                "3" = "<span>󰚺</span>";
                "4" = "<span></span>";
                "5" = "<span></span>";
                "6" = "<span>󰭛</span>";
                "7" = "<span>󱓷</span>";
                "8" = "<span>󰚸</span>";
                "9" = "<span>󰚀</span>";
                "10" = "<span>󰓓</span>";
              };
            };

            "hyprland/window" = {
              format = "{class}";
              separate-outputs = true;
              icon = true;
              icon-size = "16px";
              tooltip = false;
            };

            tray = {
              icon-size = "16px";
              spacing = "24px";
            };

            "hyprland/submap" = {
              format = "  {}";
              max-length = "50";
            };

            clock = {
              timezone = "America/New_York";
              format = "<span color='#202020' bgcolor='#8ec07c' >  </span> {:%a %d | %H:%M}";
              tooltip = true;
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              interval = 1;
            };

            network = {
              format-wifi = "󰖩 {essid}";
              format-ethernet = "{ipaddr}/{cidr}";
              tooltip-format = "{ifname} via {gwaddr}";
              format-linked = "{ifname} (No IP)";
              format-disconnected = "Disconnected ⚠";
            };

            disk = {
              format = "<span color='#202020' bgcolor='#ea6962' >  </span> {free}";
              interval = 20;
            };

            cpu = {
              format = " {usage}%";
              tooltip = true;
            };

            temperature = {
              interval = 2;
              critical-threshold = 80;
              format-critical = "<span color='#202020' bgcolor='#cc241d' >  </span> {temperatureC}°C";
              format = "<span color='#202020' bgcolor='#d8a657' >  </span> {temperatureC}°C";
            };

            memory = {
              interval = 2;
              format = "<span color='#202020' bgcolor='#458588' >  </span> {}%";
              tooltip = true;
            };

            "custom/cpu_temp" = {
              exec = "~/.config/waybar/scripts/waybarTemp.sh";
              return-type = "json";
              interval = 2;
              format = "{}";
              tooltip = false;
            };

            "custom/memory" = {
              exec = "~/.config/waybar/scripts/memory_usage.sh";
              interval = 2;
              return-type = "json";
              format = "<span color='#202020' bgcolor='#458588' >  </span> {}";
            };

            pulseaudio = {
              scroll-step = 5.0;
              format = "<span color='#202020' bgcolor='#83a598' >  </span> {volume}%";
              format-muted = "<span color='#202020' bgcolor='#ea6962' >  </span> {volume}%";
              format-bluetooth = "<span color='#202020' bgcolor='#83a598' > 󰂰 </span> {volume}%";
              format-bluetooth-muted = "<span color='#202020' bgcolor='#ea6962' > 󰂲 </span> {volume}%";
              format-source = "{volume}% ";
              on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              # on-click-right = "blueman-manager"; # TODO: add bluetui and
              # spawn in floating terminal window
              tooltip = false;
              max-volume = 100;
            };

            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                activated = "";
                deactivated = "";
              };
            };
          };
        };

        style =
          # css
          ''
            * {
              padding: 0;
              margin: 0;
              min-height: 24px;
              border-radius: 0;
              border: none;
              color: @text;
              text-shadow: none;
              transition: none;
              box-shadow: none;
            }

            #window {
              border: 3px solid @mauve;
            }

            window#waybar {
              background: none;
              font-family: Jetbrains Mono;
              font-size: 16px;
              font-weight: 600;
            }

            .modules-left,
            .modules-center,
            .modules-right {
              padding: 5px;
              background: transparent;
            }

            #window,
            #disk,
            #cpu,
            #custom-cpu_temp,
            #custom-cpu_temp.critical,
            #backlight,
            #custom-memory,
            #pulseaudio,
            #pulseaudio.muted,
            #battery,
            #battery.critical,
            #battery.warning,
            #network,
            #clock,
            #idle_inhibitor {
              padding-right: 6px;
            }

            #custom-nixos {
              color: @blue;
              padding: 0 8px;
            }

            #custom-rofi {
              color: @subtext1;
              border: 3px solid @surface0;
              padding: 0 8px;
            }

             #workspaces button {
              border: 3px solid @green;
              margin-right: 4px;
              padding: 0 8px;
            }

             #workspaces button label {
              color: @green;
            }

            /* #workspaces button:last-child {
              margin-right: 0;
            } */

            #workspaces button:hover {
              border: 3px solid @teal;
            }
            #workspaces button:hover label {
              color: @teal;
            }

            #workspaces button.visible,
            #workspaces button.visible:hover,
            #workspaces button.active,
            #workspaces button.active:hover {
              border: 3px solid @sky;
            }

            #workspaces button.visible label,
            #workspaces button.visible:hover label,
            #workspaces button.active label,
            #workspaces button.active:hover label {
              color: @sky;
            }

            #workspaces button:hover,
            #workspaces button.visible:hover,
            #workspaces button.active:hover {
              background: @lavendar;
            }

            #workspaces button.urgent {
              color: @red;
              border: 3px solid @red;
            }

            #window {
              padding: 0 8px;
            }

            #tray {
              border: 3px solid #e78a4e;
              padding: 0 8px;
            }

            #disk {
              border: 3px solid #ea6962;
            }

            #cpu {
              border: 3px solid #e78a4e;
            }

            #custom-cpu_temp {
              border: 3px solid #d8a657;
            }

            #custom-cpu_temp.critical {
              color: #cc241d;
              border: 3px solid #cc241d;
            }

            #custom-cpu_temp.unknown {
              border: 3px solid #555555;
            }

            #backlight {
              border: 3px solid #f6c657;
            }

            #custom-memory {
              border: 3px solid #458588;
            }

            #pulseaudio {
              border: 3px solid #83a598;
            }

            #pulseaudio.muted {
              border: 3px solid #ea6962;
              color: #ea6962;
            }

            #battery {
              border: 3px solid #689d68;
            }

            #battery.critical {
              border: 3px solid #cc241d;
            }

            #battery.warning {
              border: 3px solid #e78a4e;
            }

            #clock {
              border: 3px solid #8ec07c;
            }

            #network {
              border: 3px solid #d3869b;
            }

            #idle_inhibitor {
              border: 3px solid #d3869b;
            }

            #mode,
            #submap {
              background: transparent;
              color: @subtext1;
              border: @surface0;
              padding: 0 10px;
            }
          '';
      };
    };
  };
}
