# Pending-update indicator: a user timer builds main's system for this host in the background
# and counts package changes against the running one. A noctalia bar widget shows the count.
# Click: pull + switch in a terminal. Right click: check now.
{
  den.aspects.mario.homeManager =
    { lib, pkgs, ... }:
    let
      check = pkgs.writeShellApplication {
        name = "infra-update";
        runtimeInputs = with pkgs; [
          coreutils
          git
          gnugrep
          nvd
        ];
        text = builtins.readFile ./check.sh;
      };
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.infra-update = {
        Unit.Description = "Build main's system and count pending package updates";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe check;
          Environment = "PATH=/run/current-system/sw/bin"; # the system's nix, not a nixpkgs one
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
      # Hourly is one `git ls-remote` unless main moved, so a merged PR shows up within the hour.
      systemd.user.timers.infra-update = {
        Timer = {
          OnBootSec = "10min";
          OnUnitActiveSec = "1h";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      xdg.dataFile."noctalia/plugins/updates".source = ./plugin;
      xdg.configFile."noctalia/updates.toml".source = (pkgs.formats.toml { }).generate "updates.toml" {
        plugins.enabled = [ "mario/updates" ];
        widget.updates.type = "mario/updates:updates";
        # Noctalia's default end list with updates first.
        bar.main.end = [
          "updates"
          "media"
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "control-center"
          "session"
        ];
      };
    };
}
