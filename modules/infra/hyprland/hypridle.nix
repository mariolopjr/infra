{ inputs, ... }:
{
  flake-file.inputs = {
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs = {
        hyprutils.follows = "hyprland/hyprutils";
        hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };
  };

  infra.hyprland = _: {
    homeManager =
      { pkgs, ... }:
      {
        services.hypridle = {
          enable = true;
          package = inputs.hypridle.packages.${pkgs.stdenv.hostPlatform.system}.default;
          systemdTarget = "hyprland-session.target";

          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              #unlock_cmd = "killall hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "hyprctl dispatch dpms";
              ignore_dbus_inhibit = false;
              ignore_systemd_inhibit = false;
            };

            listener = [
              # if session locked, turn screen off more quickly - 30 seconds
              {
                timeout = 30;
                on-timeout = "pidof hyprlock && hyprctl dispatch dpms off";
                on-resume = "pidof hyprlock && hyprctl dispatch dpms on";
              }

              # lock session - 10 mins
              {
                timeout = 600;
                on-timeout = "loginctl lock-session";
              }

              # turn screen off - 10 mins, 30 secs
              {
                timeout = 630;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }

              # suspend seems to be broken
              # suspend - 30 mins
              # {
              #   timeout = 1800;
              #   on-timeout = "systemctl suspend";
              # }
            ];
          };
        };
      };
  };
}
