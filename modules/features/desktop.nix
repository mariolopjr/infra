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
        preservation.preserveAt."/persist".users.mario.directories = [
          ".local/state/noctalia"
          ".local/state/umbriel"
        ];
        systemd.tmpfiles.settings.noctalia."/persist/home/mario/.local/state/noctalia/settings.toml".r =
          { };

        services.displayManager.noctalia-greeter = {
          enable = true;
          settings.session.default = "umbriel";
        };

        # Login starts an ssh-agent and unlocks ~/.ssh/id_* with the login password.
        # start-umbriel imports the PAM SSH_AUTH_SOCK into the systemd user environment.
        security.pam.services.greetd.rules =
          let
            # build pam_ssh_add without installing cockpit
            pam_ssh_add = pkgs.stdenv.mkDerivation {
              pname = "pam_ssh_add";
              inherit (pkgs.cockpit) version src;
              buildInputs = [ pkgs.pam ];
              dontConfigure = true;
              buildPhase = ''
                printf '#define _GNU_SOURCE\n#define PATH_SSH_ADD "%s"\n#define PATH_SSH_AGENT "%s"\n' \
                  ${pkgs.openssh}/bin/ssh-add ${pkgs.openssh}/bin/ssh-agent > config.h
                $CC -shared -fPIC -O2 -I. src/pam-ssh-add/pam-ssh-add.c -o pam_ssh_add.so -lpam
              '';
              installPhase = "install -Dm555 pam_ssh_add.so $out/lib/security/pam_ssh_add.so";
            };
            # After greetd's `login` substack (10100): pam_unix has set PAM_AUTHTOK, pam_systemd XDG_RUNTIME_DIR.
            rule = {
              order = 10200;
              control = "optional";
              modulePath = "${pam_ssh_add}/lib/security/pam_ssh_add.so";
            };
          in
          {
            auth.ssh_add = rule;
            session.ssh_add = rule;
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
        programs.thunar.enable = true;
        xdg.mime.defaultApplications."inode/directory" = "thunar.desktop";
        environment.systemPackages = with pkgs; [
          btrfs-assistant # GUI for the /persist snapper snapshots
        ];
      };
  };
}
