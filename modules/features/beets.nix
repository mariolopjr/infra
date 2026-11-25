# Beets: tags and files the music library on the NAS share, which Navidrome on highgarden reads.
{ inputs, ... }:
{
  den.aspects.beets = {
    nixos.imports = [
      (import ./_with-preservation.nix {
        preservation.preserveAt."/persist".users.mario.directories = [ ".local/share/beets" ];
      })
    ];
    provides.to-users.homeManager.programs.beets = {
      enable = true;
      settings = {
        directory = "/mnt/music"; # NAS share; beets can't create it, so imports fail until it's mounted
        library = "~/.local/share/beets/library.db";
        statefile = "~/.local/share/beets/state.pickle";
        import = {
          write = true; # Navidrome reads tags, never this DB
          copy = true;
          log = "~/.local/share/beets/import.log";
        };
        plugins = [
          "musicbrainz"
          "fetchart" # cover.jpg next to each album
          "embedart"
          "replaygain"
          "lastgenre"
          "lyrics"
        ];
        replaygain.backend = "ffmpeg";
      };
    };
  };

  # /home is tmpfs: the library DB must live in a persisted directory.
  perSystem =
    { pkgs, ... }:
    {
      checks.beets =
        let
          cfg = inputs.self.nixosConfigurations.winterfell.config;
          beets = cfg.home-manager.users.mario.programs.beets;
          persisted = cfg.preservation.preserveAt."/persist".users.mario.directories;
        in
        if
          beets.enable
          && builtins.any (d: d.directory == "/home/mario/.local/share/beets") persisted
          && beets.settings.library == "~/.local/share/beets/library.db"
        then
          pkgs.emptyFile
        else
          throw "winterfell: beets should be enabled with its library DB in persisted ~/.local/share/beets";
    };
}
