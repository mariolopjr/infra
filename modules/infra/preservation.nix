{ inputs, ... }:
{
  # TODO: tighten permissions
  flake-file.inputs = {
    preservation.url = "github:nix-community/preservation";
  };

  infra.preservation =
    { user, ... }:
    {
      nixos = {
        imports = [
          inputs.preservation.nixosModules.default
        ];

        preservation = {
          enable = true;

          preserveAt."/persist" = {
            directories = [
              "/var/lib/systemd/timers"
              # NixOS user state
              "/var/log"
              {
                directory = "/var/lib/nixos";
                inInitrd = true;
              }
            ];

            files = [
              # auto-generated machine ID
              {
                file = "/etc/machine-id";
                inInitrd = true;
                how = "symlink";
                configureParent = true;
              }
              {
                file = "/etc/ssh/ssh_host_rsa_key";
                how = "symlink";
                configureParent = true;
              }
              {
                file = "/etc/ssh/ssh_host_ed25519_key";
                how = "symlink";
                configureParent = true;
              }
            ];

            # preserve user-specific files, implies ownership
            users = {
              ${user.userName} = {
                commonMountOptions = [
                  "x-gvfs-hide"
                ];
                directories = [
                  {
                    directory = ".ssh";
                    mode = "0700";
                  }
                  # ".config/syncthing"
                  ".local/share/direnv"
                  ".local/state/nvim"
                  ".local/state/wireplumber"
                  ".local/state/nix"
                  # ".mozilla"
                ];
                files = [
                  ".histfile"
                ];
              };
              root = {
                # specify user home when it is not `/home/${user}`
                home = "/root";
                directories = [
                  {
                    directory = ".ssh";
                    mode = "0700";
                  }
                ];
              };
            };
          };
        };
        # systemd-machine-id-commit.service would fail, but it is not relevant
        # in this specific setup for a persistent machine-id so we disable it
        systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

        # let the service commit the transient ID to the persistent volume
        systemd.services.systemd-machine-id-commit = {
          unitConfig.ConditionPathIsMountPoint = [
            ""
            "/persistent/etc/machine-id"
          ];
          serviceConfig.ExecStart = [
            ""
            "systemd-machine-id-setup --commit --root /persist"
          ];
        };

        # Create some directories with custom permissions.
        #
        # In this configuration the path `/home/butz/.local` is not an immediate parent
        # of any persisted file, so it would be created with the systemd-tmpfiles default
        # ownership `root:root` and mode `0755`. This would mean that the user `butz`
        # could not create other files or directories inside `/home/butz/.local`.
        #
        # Therefore systemd-tmpfiles is used to prepare such directories with
        # appropriate permissions.
        #
        # Note that immediate parent directories of persisted files can also be
        # configured with ownership and permissions from the `parent` settings if
        # `configureParent = true` is set for the file.
        systemd.tmpfiles.settings.preservation = {
          # "/home/${user.userName}/.config".d = {
          #   user = user.userName;
          #   group = "users";
          #   mode = "0755";
          # };
          "/home/${user.userName}/.local".d = {
            user = user.userName;
            group = "users";
            mode = "0755";
          };
          "/home/${user.userName}/.local/share".d = {
            user = user.userName;
            group = "users";
            mode = "0755";
          };
          "/home/${user.userName}/.local/state".d = {
            user = user.userName;
            group = "users";
            mode = "0755";
          };
        };
      };
    };
}
