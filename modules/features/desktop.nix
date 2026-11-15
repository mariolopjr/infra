# Wayland desktop: noctalia shell on umbriel using noctalia-greeter.
{
  den.aspects.desktop = {
    nixos =
      { pkgs, ... }:
      {
        boot.consoleLogLevel = 3;
        boot.kernelParams = [
          "quiet"
          "udev.log_level=3"
          "systemd.show_status=auto"
        ];
        programs.umbriel.enable = true;

        programs.noctalia = {
          enable = true;
          systemd.enable = true;
          recommendedServices.enable = true;
        };
        # Keep Noctalia's state (setup marker, launcher usage, catalogs) but drop its GUI
        # overrides each boot
        preservation.preserveAt."/persist".users.mario.directories = [ ".local/state/noctalia" ];
        systemd.tmpfiles.settings.noctalia."/persist/home/mario/.local/state/noctalia/settings.toml".r =
          { };

        services.displayManager.noctalia-greeter = {
          enable = true;
          settings.session.default = "umbriel";
        };

        hardware.graphics.enable = true;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };

        fonts.packages = with pkgs; [
          inter
          nerd-fonts.jetbrains-mono
          noto-fonts
          noto-fonts-color-emoji
        ];
        # xdg-terminal-exec: apps and launchers that ask for "the terminal" use ghostty.
        xdg.terminal-exec = {
          enable = true;
          settings.default = [ "com.mitchellh.ghostty.desktop" ];
        };
        environment.systemPackages = with pkgs; [
          btrfs-assistant # GUI for the /persist snapper snapshots
        ];
      };
  };
}
