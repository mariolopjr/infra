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

            height = 20;
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
            ];

            # tweak scripts
            "custom/nixos" = {
              format = "";
              #on-click = "rofi -show drun -disable-history -show-icons";
              #on-click-right = "~/.config/custom_scripts/power.sh";
              escape = true;
              tooltip = true;
              tooltip-format = "btw";
            };

            "hyprland/workspaces" = {
              disable-scroll = true;
              active-only = false;
              all-outputs = true;
              warp-on-scroll = false;
              format = "{icon}";
              format-icons = {
                "1" = "<span>󰧨</span>";
                "2" = "<span>󰈹</span>";
                "3" = "<span></span>";
                "4" = "<span></span>";
                "5" = "<span></span>";
                "6" = "<span>󰭛</span>";
                "7" = "<span>󱓷</span>";
                "8" = "<span>󰚀</span>";
              };
            };

            "hyprland/window" = {
              format = "<span color='#202020' bgcolor='#d3869b' > 󰣆 </span> {class}";
              separate-outputs = true;
              icon = false;
              tooltip = false;
            };

            tray = {
              icon-size = 16;
              spacing = 8;
            };

            "hyprland/submap" = {
              format = " {}";
              max-length = 50;
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
              # scroll-step = 1; # %, can be a float
              format = "<span color='#202020' bgcolor='#83a598' >  </span> {volume}%";
              format-muted = "<span color='#202020' bgcolor='#ea6962' >  </span> {volume}%";
              format-bluetooth = "<span color='#202020' bgcolor='#83a598' > 󰂰 </span> {volume}%";
              format-bluetooth-muted = "<span color='#202020' bgcolor='#ea6962' > 󰂲 </span> {volume}%";
              format-source = "{volume}% ";
              on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
              on-click-right = "blueman-manager";
              tooltip = false;
              max-volume = 130;
            };
          };
        };

        style =
          # css
          ''
            * {
              padding: 0;
              margin: 0;
              min-height: 0;
              border-radius: 0;
              border: none;
              text-shadow: none;
              transition: none;
              box-shadow: none;
            }

            #window {
              border: 3px solid #d3869b;
            }

            window#waybar {
              color: #ebdbb2;
              background: none;
              font-family: Monaspace Neon;
              font-size: 16px;
              font-weight: 900;
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
            #clock {
              padding: 0 2px;
            }

            #custom-rofi {
              color: #83a598;
              border: 3px solid #83a598;
              padding: 0 8px;
            }

            #workspaces button {
              color: #fff4d2;
              border: 3px solid #fff4d2;
              margin-right: 5px;
              min-width: 20px;
              padding: 0 5;
            }

            #workspaces button:last-child {
              margin-right: 0;
            }

            #workspaces button:hover {
              color: #d3869b;
              border: 3px solid #d3869b;
            }

            #workspaces button.visible,
            #workspaces button.visible:hover,
            #workspaces button.active,
            #workspaces button.active:hover {
              color: #8ec07c;
              border: 3px solid #8ec07c;
            }

            #workspaces button.urgent {
              color: #ea6962;
              border: 3px solid #ea6962;
            }

            #tray {
              background: #222222;
              border: 3px solid #e78a4e;
              padding: 0 8;
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

            #mode,
            #submap {
              background: transparent;
              color: @text;
              border: @surface0;
              padding: 0 10;
            }
          '';
      };
    };
  };
}
