{ inputs, ... }:
{
  flake-file.inputs.ghostty = {
    url = "github:ghostty-org/ghostty";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  infra.ghostty = _: {
    homeManager =
      { pkgs, ... }:
      {
        programs.ghostty = {
          enable = true;
          package = inputs.ghostty.packages.${pkgs.system}.default;

          settings = {
            # Font
            font-family = "JetBrainsMono";
            font-size = 13;
            font-thicken = true;
            # font-feature = [
            #   "calt" # variable width / texture healing
            #   "ss01" # equals ligatures: ==
            #   # "ss02", # less/greater than ligatures: <=
            #   "ss03" # arrow ligatures: ->
            #   "ss04" # markup ligatures: </
            #   "ss05" # F# ligatures: |>
            #   "ss06" # repeating character ligatures: ###
            #   "ss07" # colon ligatures: ::
            #   "ss08" # period ligatures: ..=
            #   "ss09" # less/greater than ligatures with other characters: =<<
            #   "ss10" # other tag ligatures: #[
            #   "liga" # dynamic spacing for repeating char patterns
            # ];

            # Look and Feel
            theme = "catppuccin-macchiato";
            bold-is-bright = true;
            adjust-cursor-thickness = 10;
            adjust-underline-position = 3;
            mouse-hide-while-typing = true;
            window-decoration = false;
            window-padding-balance = true;
            window-padding-x = 15;
            window-padding-y = 15;

            # Behavior
            quit-after-last-window-closed = true;
            quit-after-last-window-closed-delay = "5m";

            # Other
            # TODO: use getExe here
            command = "${pkgs.fish}/bin/fish -l";
            copy-on-select = true;
            auto-update = "off";

            # Key bindings
            keybind = [
              "ctrl+equal=unbind"
              "ctrl+-=unbind"
              # other
              "super+k=clear_screen"
              "global:ctrl+`=toggle_quick_terminal"
            ];
          };
        };
      };
  };
}
