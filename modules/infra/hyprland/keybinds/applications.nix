{ inputs, ... }:
{
  infra.hyprland = _: {
    homeManager =
      { lib, pkgs, ... }:
      {
        wayland.windowManager.hyprland.settings = {
          bindd =
            let
              # terminal = "ghostty +new-window";
              # terminal = "${lib.getExe pkgs.wezterm}";
              terminal = "${lib.getExe inputs.ghostty.packages.${pkgs.system}.default} +new-window";
              # TODO: add options to user object
              # if meta.programs.terminal == "ghostty"
              # then "ghostty +new-window"
              # else "uwsm app -- ghostty";
            in
            [
              # Open applications
              "$mainMod, RETURN, Open terminal, exec, ${terminal}"
              "$mainMod, B, Open browser, exec, firefox"
              "$mainMod, E, Open terminal terminal file manager, exec, uwsm app -- xdg-terminal-exec yazi"
              "$mainMod SHIFT, E, Open file manager, exec, uwsm app -- nautalus"
              # TODO: install calculator
              # ", XF86Calculator, Open calculator, exec, ${runOnce "gnome-calculator"}"

              # Vesktop
              "CTRL SHIFT, M, Mute on vesktop, pass, class:^(vesktop)$"
              "CTRL SHIFT, D, Deafen on vesktop, pass, class:^(vesktop)$"

              # hypr
              "$mainMod, L, Start hyprlock, exec, hyprlock"
              "$mainMod, Q, Close window, killactive,"
              #"$mainMod SHIFT, Q, Exit window (kill), exit,"

              # volume
              ", XF86AudioRaiseVolume, Raise volume by 10%, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+"
              ", XF86AudioLowerVolume, Lower volume by 10%, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"
              ", XF86AudioMute, Mute volume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ", XF86AudioPlay, Play/Pause, exec, playerctl play-pause"
              ", XF86AudioPause, Pause, exec, playerctl pause"
              ", XF86AudioNext, Next, exec, playerctl next"
              ", XF86AudioPrev, Previous, exec, playerctl previous"
            ];
        };
      };
  };
}
