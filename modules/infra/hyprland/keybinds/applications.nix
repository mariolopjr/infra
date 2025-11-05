{
  infra.hyprland = _: {
    homeManager = {
      wayland.windowManager.hyprland.settings = {
        bindd =
          let

            terminal = "ghostty +new-window";
            # TODO: add options to user object
            # if meta.programs.terminal == "ghostty"
            # then "ghostty +new-window"
            # else "uwsm app -- ghostty";
          in
          [
            # Open applications
            "$mainMod, RETURN, Open terminal, exec, ${terminal}"
            "$mainMod, B, Open browser, exec, uwsm app -- firefox"
            # "$mainMod, B, Open browser, exec, uwsm app -- ${meta.programs.browser}"
            "$mainMod, E, Open terminal terminal file manager, exec, uwsm app -- xdg-terminal-exec yazi"
            "$mainMod SHIFT, E, Open file manager, exec, uwsm app -- nautalus"
            # TODO: install calculator
            # ", XF86Calculator, Open calculator, exec, ${runOnce "gnome-calculator"}"

            # Vesktop
            "CTRL SHIFT, M, Mute on vesktop, pass, class:^(vesktop)$"
            "CTRL SHIFT, D, Deafen on vesktop, pass, class:^(vesktop)$"

            # hypr
            "$mainMod SHIFT, Q, Exit hyprland, exit,"
          ];
      };
    };
  };
}
