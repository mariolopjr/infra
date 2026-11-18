# Ephemeral root and /home: both are the tmpfs root, state named here is bind-mounted from
# /persist (snapshotted) or /cache (not) by static systemd mount units and tmpfiles.
# /nix and /var/log are subvolumes.
{ inputs, ... }:
{
  den.aspects.disks.nixos =
    { config, lib, ... }:
    let
      mario = {
        directories = [
          ".config/infra"
          {
            directory = ".ssh";
            mode = "0700";
          }
          ".config/gh"
          ".claude"
          ".local/share/nvim" # vim.pack plugins
          ".local/state/nvim" # undo, shada
          ".local/share/zoxide"
          ".local/share/direnv" # allow list
          ".local/state/wireplumber" # volumes, default devices
          ".local/state/rex" # host-id, server snapshots
          ".steam" # registry.vdf (settings), steam.token
          "code"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
        ];
        # Symlinks: replacing a bind-mounted file by rename fails (EBUSY). Claude writes through the link.
        files =
          map
            (file: {
              inherit file;
              how = "symlink";
            })
            [
              ".claude.json"
              ".config/nushell/history.txt"
            ];
      };
      cached = [
        ".cache"
        ".cargo"
        "go"
      ];
    in
    {
      imports = [ inputs.preservation.nixosModules.default ];
      fileSystems."/persist".neededForBoot = true;

      preservation = {
        enable = true;
        preserveAt."/persist" = {
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
          ]
          # Every host key sshd generates, with its .pub (keygen skips the pair if the private key exists).
          ++ lib.concatMap (
            k:
            map
              (file: {
                inherit file;
                how = "symlink";
                configureParent = true;
              })
              [
                k.path
                "${k.path}.pub"
              ]
          ) config.services.openssh.hostKeys;
          directories = [
            {
              directory = "/var/lib/nixos"; # uid/gid allocations
              inInitrd = true;
            }
            "/var/lib/systemd" # timers, linger, random-seed, coredumps
            "/etc/NetworkManager/system-connections"
            "/var/lib/NetworkManager"
            "/var/lib/bluetooth"
            "/var/lib/fwupd"
            {
              directory = "/var/lib/sbctl"; # secure boot signing keys
              mode = "0700";
            }
            # coolercontrold's UI password, tokens, TLS cert. In initrd so activation's copy of the
            # Nix-managed config.toml/overrides.toml (fans.nix) lands on top of it, not under it.
            {
              directory = "/etc/coolercontrol";
              inInitrd = true;
            }
          ];
          users.mario = mario;
        };
        preserveAt."/cache".users.mario.directories = cached;
      };
      # e2e VM disks: unsnapshotted and nodatacow so qcow2 rewrites don't fragment
      systemd.tmpfiles.settings.e2e."/cache/e2e" = {
        d = {
          user = "mario";
          group = "users";
          mode = "0755";
        };
        h.argument = "+C";
      };

      services.snapper.configs.persist = {
        SUBVOLUME = "/persist";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
      };
      security.sudo.extraConfig = "Defaults lecture = never";
      # machine-id is already a bind mount from /persist; commit would fail.
      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

      # /etc/shadow is on tmpfs, so passwords come from a hash the installer writes.
      users.mutableUsers = false;
      users.users.mario.hashedPasswordFile = "/persist/passwords/mario";
    };
}
