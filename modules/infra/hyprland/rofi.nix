{
  infra.hyprland = _: {
    homeManager =
      { pkgs, ... }:
      {
        programs.rofi = {
          enable = true;
        };

        wayland.windowManager.hyprland = {
          settings = {
            "$rofiDrun" = "rofi -show drun -disable-history -show-icons";
            "$rofiRun" = "rofi -show run -disable-history";
            "$rofiWindows" = "rofi -show window -show-icons";
            # TODO: add emoji support using rofimoji
            "$powerMenu" = "${pkgs.writeShellScript "power-menu"
              # bash
              ''
                suspend="systemctl suspend && hyprlock"
                logout="hyprctl dispatch exit 0"
                chosen=$(printf "Log Out\nSuspend\nRestart\nPower Off" | rofi -dmenu -i)

                # Perform the action based on user choice
                case "$chosen" in
                    "Log Out") $logout ;;
                    "Suspend") eval $suspend ;;
                    "Restart") systemctl reboot ;;
                    "Power Off") systemctl poweroff ;;
                    *) exit 1 ;;
                esac
              ''
            }";

            bindd = [
              "$mainMod, r, Rofi submap, submap, rofi"
            ];
          };

          submaps = {
            rofi = {
              settings = {
                bindd = [
                  ", F, Rofi run desktop applications, exec, $rofiDrun & $resetSubmap"
                  ", T, Rofi run applications (including cli), exec, $rofiRun & $resetSubmap"
                  ", W, Rofi windows, exec, $rofiWindows & $resetSubmap"
                  ", P, Rofi power menu, exec, $powerMenu & $resetSubmap"
                  ", catchall, Rofi submap reset, submap, reset"
                ];
              };
            };
          };
        };
      };
  };
}
