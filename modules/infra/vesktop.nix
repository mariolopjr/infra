{ inputs, ... }:
{
  flake-file.inputs = {
    nixcord.url = "github:kaylorben/nixcord";
  };

  infra.nixcord = _: {
    homeManager =
      { ... }:
      {
        imports = [ inputs.nixcord.homeModules.nixcord ];

        programs.nixcord = {
          enable = true;
          vesktop.enable = true;

          discord.branch = "stable";

          extraConfig.SKIP_HOST_UPDATE = true;

          vesktop.settings = {
            appBadge = false;
            arRPC = true;
            autoMinimizeToTray = true;
            checkUpdates = false;
            clickTrayToShowHide = true;
            discordBranch = "stable";
            minimizeToTray = true;
            transparencyOption = "acrylic";
            tray = true;
          };

          vesktop.state = {
            firstLaunch = false;
            windowBounds = {
              x = 0;
              y = 0;
              width = 1600;
              height = 900;
            };
          };

          config = {
            autoUpdate = false;
            autoUpdateNotification = false;
            notifyAboutUpdates = false;
          };
        };
      };
  };
}
