{ inputs, ... }:
{
  flake-file.inputs = {
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  infra.kde = _: {
    nixos =
      { pkgs, ... }:
      {
        services = {
          desktopManager.plasma6.enable = true;
          displayManager.sddm.enable = true;
          displayManager.sddm.wayland.enable = true;
        };

        environment.systemPackages = with pkgs; [
          kdePackages.kcalc
          kdePackages.kcharselect
          kdePackages.kcolorchooser
          kdePackages.ksshaskpass
          kdePackages.isoimagewriter
          kdePackages.partitionmanager
          wl-clipboard
        ];

        environment.plasma6.excludePackages = with pkgs; [
          kdePackages.elisa
          kdePackages.kate
          kdePackages.konsole
          kdePackages.ktexteditor
        ];
      };

    homeManager =
      { lib, pkgs, ... }:
      {
        imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

        programs.plasma = {
          enable = true;
          overrideConfig = true;

          workspace = {
            colorScheme = "BreezeDark";
            cursor = {
              size = 24;
            };
            iconTheme = "Breeze-Dark";
            lookAndFeel = "org.kde.breezedark.desktop";
            # wallpaper = "";
          };

          hotkeys.commands."launch-ghostty" =
            let
              terminal = "${lib.getExe inputs.ghostty.packages.${pkgs.system}.default} +new-window";
            in
            {
              name = "Launch Ghostty";
              key = "Meta+Enter";
              command = "${terminal}";
            };

          kwin = {
            edgeBarrier = 0;
            cornerBarrier = false;

            scripts.polonium.enable = true;
          };

          krunner = {
            activateWhenTypingOnDesktop = true;
            historyBehavior = "enableSuggestions";
            position = "center";
          };

          kscreenlocker = {
            lockOnResume = true;
            timeout = 15;
          };

          powerdevil = {
            AC.autoSuspend.action = "nothing";
            AC.autoSuspend.idleTimeout = null;
            AC.powerProfile = "performance";
          };

          shortcuts = {
            # kwin = {
            "services/org.kde.dolphin.desktop" = {
              _launch = "Meta+Alt+E";
            };

            "services/firefox.desktop" = {
              new-window = "Meta+Alt+B";
            };

            "com.mitchellh.ghostty"."CTRL+grave" = "Ctrl+`";
            # }
          };

          configFile = {
            kwinrc.Desktops.Number = {
              value = 4;
              immutable = true;
            };

            kspashrc.KSplash.Theme = "org.kde.breeze.desktop";
          };
        };
      };
  };
}
