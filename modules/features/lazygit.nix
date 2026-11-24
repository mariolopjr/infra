let
  c = (import ./theme/_palette.nix).dark;
in
{
  den.aspects.lazygit.homeManager.programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [
            c.primary
            "bold"
          ];
          inactiveBorderColor = [ c.on_surface_variant ];
          optionsTextColor = [ c.primary ];
          selectedLineBgColor = [ c.surface_container ];
          cherryPickedCommitBgColor = [ c.hover ];
          cherryPickedCommitFgColor = [ c.primary ];
          unstagedChangesColor = [ c.error ];
          defaultFgColor = [ c.on_surface ];
          searchingActiveBorderColor = [ c.terminal.normal.yellow ];
          authorColors."*" = c.secondary;
        };
      };
      disableStartupPopups = true;
      git.overrideGpg = true;
    };
  };
}
