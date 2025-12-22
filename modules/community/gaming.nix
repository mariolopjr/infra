{
  infra.gaming.nixos =
    { pkgs, ... }:
    {
      boot.kernel.sysctl = {
        # default on some gaming (SteamOS) and desktop (Fedora) distributions
        # might help with gaming performance
        "vm.max_map_count" = 2147483642;
      };

      environment.sessionVariables = {
        STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
      };

      programs = {
        gamescope = {
          enable = true;
          capSysNice = true;
        };

        gamemode = {
          enable = true;
          enableRenice = true;
          settings = {
            general = {
              softrealtime = "auto";
              renice = 15;
            };
          };
        };

        steam = {
          enable = true;

          # An attempt to reduce the closure size of Steam (which by default is *massive* - around 15 gigs)
          # This removes game-specific libraries crammed into the Steam runtime
          # by upstream (nixpkgs) packaging to mitigate errors due to missing libraries.
          # As we strip those libraries, we gain space and lose compatibility - which
          # unfortunately means that it is up to *us* to identify necessary libraries
          # and stick them here.
          package = pkgs.steam.override {
            extraEnv = {
              # MANGOHUD = true;
              SDL_VIDEODRIVER = "x11";
            };

            extraLibraries =
              ps: with ps; [
                atk
              ];

            extraPkgs =
              p: with p; [
                # mangohud
                gamemode
              ];
          };

          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = false;
          gamescopeSession.enable = true;
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
        };
      };

      services.ratbagd.enable = true;

      # udev rules for various controller compatibility.
      services.udev.extraRules = ''
        # This rule is needed for basic functionality of the controller in
        # Steam and keyboard/mouse emulation
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
        # Valve HID devices over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"
        # Valve HID devices over bluetooth hidraw
        KERNEL=="hidraw*", KERNELS=="*28DE:*", MODE="0666"
        # DualShock 4 over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
        # Dualsense over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666"
        # DualShock 4 wireless adapter over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ba0", MODE="0666"
        # DualShock 4 Slim over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
        # DualShock 4 over bluetooth hidraw
        KERNEL=="hidraw*", KERNELS=="*054C:05C4*", MODE="0666"
        # DualShock 4 Slim over bluetooth hidraw
        KERNEL=="hidraw*", KERNELS=="*054C:09CC*", MODE="0666"
      '';

      security.wrappers.gamemode = {
        owner = "root";
        group = "root";
        source = "${pkgs.gamemode}/bin/gamemoderun";
        capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
      };
    };
}
