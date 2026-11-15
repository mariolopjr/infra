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
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
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
