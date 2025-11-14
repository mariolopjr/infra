{ inputs, ... }:
{
  flake-file.inputs = {
    ghostty.url = "github:ghostty-org/ghostty";
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
            font-family = "Monaspace Neon";
            font-size = 14;
            font-thicken = true;
            font-feature = [
              "calt" # variable width / texture healing
              "ss01" # equals ligatures: ==
              # "ss02", # less/greater than ligatures: <=
              "ss03" # arrow ligatures: ->
              "ss04" # markup ligatures: </
              "ss05" # F# ligatures: |>
              "ss06" # repeating character ligatures: ###
              "ss07" # colon ligatures: ::
              "ss08" # period ligatures: ..=
              "ss09" # less/greater than ligatures with other characters: =<<
              "ss10" # other tag ligatures: #[
              "liga" # dynamic spacing for repeating char patterns
            ];

            # Look and Feel
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
            command = "${pkgs.fish}/bin/fish -l";
            copy-on-select = true;
            auto-update = "off";

            # Key bindings
            keybind = [
              # splits
              "ctrl+h=goto_split:left"
              "ctrl+j=goto_split:bottom"
              "ctrl+k=goto_split:top"
              "ctrl+l=goto_split:right"
              "ctrl+shift+h=new_split:left"
              "ctrl+shift+j=new_split:down"
              "ctrl+shift+k=new_split:up"
              "ctrl+shift+l=new_split:right"
              "ctrl+alt+h=resize_split:left,30"
              "ctrl+alt+j=resize_split:down,30"
              "ctrl+alt+k=resize_split:up,30"
              "ctrl+alt+l=resize_split:right,30"

              # other
              "super+alt+enter=new_split:auto"
              "super+k=clear_screen"
              "global:ctrl+`=toggle_quick_terminal"
            ];
          };
        };
      };
  };
}
