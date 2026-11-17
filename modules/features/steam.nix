# Steam with Proton-GE, gamemode and gamescope. Its whole folder, ~/.local/share/Steam (client,
# default library, Proton prefixes, shader cache), is the @games subvolume on the main disk, so
# installs and updates stay out of the snapper-snapshotted /persist. Second library: /data/games.
{
  den.aspects.gaming.nixos =
    { lib, pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        localNetworkGameTransfers.openFirewall = true;
      };
      programs.gamemode.enable = true; # launch option: gamemoderun %command%
      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };

      disko.devices.disk.main.content.partitions.root.content.content.subvolumes."@games" = {
        mountpoint = "/home/mario/.local/share/Steam";
        # Same compress level as the other subvolumes (it is filesystem-wide). The
        # games-nocompress service turns it off for this tree.
        mountOptions = [
          "compress=zstd:1"
          "noatime"
        ];
      };

      # Ensure game files are not compressed
      systemd.services.games-nocompress = {
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        unitConfig.RequiresMountsFor = [
          "/home/mario/.local/share/Steam"
          "/data/games"
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.btrfs-progs}/bin/btrfs property set /home/mario/.local/share/Steam compression none
          ${pkgs.btrfs-progs}/bin/btrfs property set /data/games compression none
        '';
      };

      systemd.tmpfiles.settings.steam-libraries =
        lib.genAttrs
          [
            "/data/games"
            "/home/mario/.local/share/Steam"
          ]
          (_: {
            d = {
              user = "mario";
              group = "users";
              mode = "0755";
            };
          });
    };
}
