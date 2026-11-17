# Desk peripherals. Studio Display XDR audio and camera are plain USB class devices; its
# brightness is a HID feature report (no DDC), set by asdbctl from the display's light sensor.
{
  den.aspects.peripherals.nixos =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.asdbctl # monitor brightness control
      ];
      services.udev.packages = [ pkgs.asdbctl ]; # hidraw access for the logged-in user
      # STM32 ROM DFU bootloader
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", TAG+="uaccess"
      '';

      # Brightness % = SLOPE * log10(lux), checked every 5s; written only on a STEP-point change,
      # so a manual `asdbctl up/down` holds until the room light moves.
      # SLOPE 25 matched the display's own setting (62%) at ~300 lux on the first boot.
      systemd.user.services.studio-display-brightness = {
        description = "Studio Display XDR auto-brightness";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        environment = {
          SLOPE = "25";
          STEP = "5";
        };
        serviceConfig = {
          Restart = "always";
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "studio-display-brightness";
              runtimeInputs = [
                pkgs.asdbctl
                pkgs.coreutils
                pkgs.gawk
                pkgs.gnugrep
              ];
              text = builtins.readFile ./studio-display-brightness.sh;
            }
          );
        };
      };

      # Logitech Unifying/Bolt receiver: pairing, battery, button settings (solaar).
      hardware.logitech.wireless.enable = true;
      programs.solaar.enable = true;
    };
}
