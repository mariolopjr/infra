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

        # nixpkgs.overlays = lib.singleton (
        #   final: prev: {
        #     kdePackages = prev.kdePackages // {
        #       plasma-workspace =
        #         let
        #
        #           # the package we want to override
        #           basePkg = prev.kdePackages.plasma-workspace;
        #
        #           # a helper package that merges all the XDG_DATA_DIRS into a single directory
        #           xdgdataPkg = pkgs.stdenv.mkDerivation {
        #             name = "${basePkg.name}-xdgdata";
        #             buildInputs = [ basePkg ];
        #             dontUnpack = true;
        #             dontFixup = true;
        #             dontWrapQtApps = true;
        #             installPhase = ''
        #               mkdir -p $out/share
        #               ( IFS=:
        #                 for DIR in $XDG_DATA_DIRS; do
        #                   if [[ -d "$DIR" ]]; then
        #                     cp -r $DIR/. $out/share/
        #                     chmod -R u+w $out/share
        #                   fi
        #                 done
        #               )
        #             '';
        #           };
        #
        #           # undo the XDG_DATA_DIRS injection that is usually done in the qt wrapper
        #           # script and instead inject the path of the above helper package
        #           derivedPkg = basePkg.overrideAttrs {
        #             preFixup = ''
        #               for index in "''${!qtWrapperArgs[@]}"; do
        #                 if [[ ''${qtWrapperArgs[$((index+0))]} == "--prefix" ]] && [[ ''${qtWrapperArgs[$((index+1))]} == "XDG_DATA_DIRS" ]]; then
        #                   unset -v "qtWrapperArgs[$((index+0))]"
        #                   unset -v "qtWrapperArgs[$((index+1))]"
        #                   unset -v "qtWrapperArgs[$((index+2))]"
        #                   unset -v "qtWrapperArgs[$((index+3))]"
        #                 fi
        #               done
        #               qtWrapperArgs=("''${qtWrapperArgs[@]}")
        #               qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "${xdgdataPkg}/share")
        #               qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "$out/share")
        #             '';
        #           };
        #
        #         in
        #         derivedPkg;
        #     };
        #   }
        # );
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
            iconTheme = "breeze-dark";
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

            ksplashrc.KSplash.Theme = "org.kde.breeze.desktop";
          };
        };
      };
  };
}
