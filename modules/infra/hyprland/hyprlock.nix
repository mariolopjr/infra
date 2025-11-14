{ inputs, ... }:
{
  flake-file.inputs = {
    hyprlock = {
      url = "github:hyprwm/hyprlock";
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
        programs.hyprlock = {
          enable = true;
          package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.default;

          settings = {
            general = {
              hide_cursor = true;
            };

            background = [
              {
                monitor = "";
                # path = "$HOME/.config/background";
                blur_passes = 0;
                color = "$base";
              }
            ];

            label = [
              # layout
              # TODO: use this as an example label to add relevant info
              {
                monitor = "";
                text = "Layout: $LAYOUT";
                color = "$text";
                font_size = 25;
                font_family = "$font";
                position = "30, -30";
                halign = "left";
                valign = "top";
              }

              # time
              {
                monitor = "";
                text = "$TIME";
                color = "$text";
                font_size = 90;
                font_family = "$font";
                position = "-30, 0";
                halign = "right";
                valign = "top";
              }

              # date
              {
                monitor = "";
                text = ''
                  cmd[update:43200000] date +"%A, %d %B %Y"
                '';
                color = "$text";
                font_size = 25;
                font_family = "$font";
                position = "-30, -150";
                halign = "right";
                valign = "top";
              }
            ];

            # input
            input-field = [
              {
                monitor = "";
                size = "300, 60";
                outline_thickness = 4;
                dots_size = 0.2;
                dots_spacing = 0.2;
                dots_center = true;
                outer_color = "$accent";
                inner_color = "$surface0";
                font_color = "$text";
                fade_on_empty = false;
                placeholder_text = ''
                  <span foreground="##$textAlpha"><i>󰌾 Logged in as </i><span foreground="##$accentAlpha">$USER</span></span>
                '';
                hide_input = false;
                check_color = "$accent";
                fail_color = "$red";
                fail_text = ''
                  <i>$FAIL <b>($ATTEMPTS)</b></i>
                '';
                capslock_color = "$yellow";
                position = "0, -47";
                halign = "center";
                valign = "center";
              }
            ];
          };
        };
      };
  };
}
