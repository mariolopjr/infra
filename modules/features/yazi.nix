# Terminal file manager
{
  den.aspects.yazi.homeManager =
    { lib, ... }:
    let
      c = (import ./theme/_palette.nix).dark;
      accent = {
        fg = c.primary;
      };
      main = fg: bg: {
        inherit fg bg;
        bold = true;
      };
      alt = fg: {
        inherit fg;
        bg = c.surface_container;
      };
      popup = {
        border = accent;
      };
      titled = popup // {
        title = accent;
      };
    in
    {
      programs.yazi = {
        enable = true;
        theme =
          lib.genAttrs [
            "confirm"
            "spot"
            "input"
            "tasks"
          ] (_: titled)
          // lib.genAttrs [
            "which"
            "pick"
            "cmp"
            "help"
          ] (_: popup)
          // {
            mgr = {
              cwd.fg = c.tertiary;
              border_style.fg = c.on_surface_variant;
              find_keyword = {
                fg = c.terminal.normal.yellow;
                bold = true;
                underline = true;
              };
            };
            indicator = {
              current = {
                bg = c.surface_container;
                bold = true;
              };
              parent.bg = c.surface_container;
            };
            tabs = {
              active = main c.on_primary c.primary;
              inactive = alt c.primary;
            };
            mode = {
              normal_main = main c.on_primary c.primary;
              normal_alt = alt c.primary;
              select_main = main c.on_secondary c.secondary;
              select_alt = alt c.secondary;
              unset_main = main c.on_error c.error;
              unset_alt = alt c.error;
            };
            which = popup // {
              cand.fg = c.tertiary;
              desc.fg = c.secondary;
              rest.fg = c.outline_variant;
              separator_style.fg = c.outline_variant;
            };
            pick = popup // {
              active = accent // {
                bold = true;
              };
            };
            tasks = titled // {
              hovered = accent // {
                bold = true;
              };
            };
            help = popup // {
              chord.fg = c.tertiary;
            };
          };
      };
    };
}
