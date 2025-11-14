{ inputs, ... }:

{
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  infra.impermanence =
    { user, ... }:
    {
      nixos = {
        imports = [
          inputs.impermanence.nixosModules.impermanence
        ];

        # configure directories to persist
        environment.persistence."/persist" = {
          hideMounts = true;

          directories = [
            "/var/log"
            "/var/lib/bluetooth"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/etc/NetworkManager/system-connections"
          ];

          files = [
            "/etc/machine-id"
            {
              file = "/var/lib/sops-nix/key.txt";
              parentDirectory = {
                mode = "u=rwx,g=,o=";
              };
            }
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
          ];

          users.${user.userName} = {
            # TODO: review application data like devenv, etc. and add here
            directories = [
              "Downloads"
              "Music"
              "Pictures"
              "Documents"
              "Videos"

              # infra repo that manages all nixos/nix/darwin systems
              "infra"

              # {
              #   directory = ".gnupg";
              #   mode = "0700";
              # }
              {
                directory = ".ssh";
                mode = "0700";
              }
              # { directory = ".nixops"; mode = "0700"; }

              # ".config/discord"

              ".local/share/direnv"
              # { directory = ".local/share/keyrings"; mode = "0700"; }
              ".local/share/Steam"

              # ".mozilla/firefox"
            ];

            # TODO: fish history, what about fish autocomplete and plugin data?
            files = [
              ".bash_history"
              ".local/share/fish/fish_history"
              ".local/share/nix/repl-history"
            ];
          };
        };

        # configure system for persistence and root volume wiping
        fileSystems."/persist".neededForBoot = true;
        virtualisation.fileSystems."/persist".neededForBoot = true;

        boot.initrd.systemd = {
          enable = true;
          services.rollback = {
            description = "Restore BTRFS root subvolume to a blank snapshot";
            wantedBy = [ "initrd.target" ];

            # LUKS/TPM process. If you have named your device mapper something other
            # than 'cryptroot', then @cryptroot will have a different name. Adjust accordingly.
            after = [ "systemd-cryptsetup@cryptroot.service" ];

            # Before mounting the system root (/sysroot) during the early boot process
            before = [ "sysroot.mount" ];

            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = ''
              mkdir -p /mnt

              # We first mount the BTRFS root to /mnt
              # so we can manipulate btrfs subvolumes.
              mount -o subvol=/ /dev/mapper/cryptroot /mnt

              # While we're tempted to just delete /root and create
              # a new snapshot from /root-blank, if root is
              # populated with subvolumes,
              # `btrfs subvolume delete` will fail.

              btrfs subvolume list -o /mnt/root |
                cut -f9 -d' ' |
                while read subvolume; do
                  echo "deleting /$subvolume subvolume..."
                  btrfs subvolume delete "/mnt/$subvolume"
                done &&
                echo "deleting /root subvolume..." &&
                btrfs subvolume delete /mnt/root
              echo "restoring blank /root subvolume..."
              btrfs subvolume snapshot /mnt/root-blank /mnt/root

              # Once we're done rolling back to a blank snapshot,
              # we can unmount /mnt and continue on the boot process.
              umount /mnt
            '';
          };
        };
      };
    };
}
