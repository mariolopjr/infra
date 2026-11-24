{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      ofSystem = lib.filterAttrs (
        n: c: !lib.hasPrefix "installer-" n && c.pkgs.stdenv.hostPlatform.system == system
      );
      hosts = ofSystem inputs.self.nixosConfigurations;
      check =
        name: c:
        let
          cfg = c.config;
          marioDirs = cfg.preservation.preserveAt."/persist".users.mario.directories or [ ];
          failed = lib.filter (x: !x.ok) [
            {
              # Not included in @persist (snapper would snapshot every game update) and the tmpfs root.
              ok =
                !cfg.programs.steam.enable
                || (
                  lib.hasInfix "subvol=@games" (
                    lib.concatStringsSep "," (cfg.fileSystems."/home/mario/.local/share/Steam".options or [ ])
                  )
                  && cfg.fileSystems ? "/data"
                  && !lib.any (d: d.directory == "/home/mario/.local/share/Steam") marioDirs
                );
              msg = "steam (client and default library) needs @games at ~/.local/share/Steam, not on /persist";
            }
            {
              # /home is tmpfs too
              ok = !(cfg.fileSystems ? "/home");
              msg = "/home is a disk mount, not part of the tmpfs root";
            }
          ];
        in
        if failed == [ ] then
          pkgs.emptyFile
        else
          throw "${name}: ${lib.concatMapStringsSep ", " (x: x.msg) failed}";

      # Every ~/.claude command in the managed Claude settings is a file home-manager links.
      claudeHosts = lib.filterAttrs (_: c: (c.config.home-manager.users.mario or { }) ? claude) (
        ofSystem (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations)
      );
      claudeCheck =
        name: c:
        let
          hm = c.config.home-manager.users.mario;
          s = hm.claude.settings;
          commands =
            lib.concatMap (m: map (h: h.command) (m.hooks or [ ])) (lib.flatten (lib.attrValues s.hooks))
            ++ [ s.statusLine.command ];
          paths = map (cmd: lib.removePrefix "~/" (lib.head (lib.splitString " " cmd))) (
            lib.filter (lib.hasPrefix "~/.claude/") commands
          );
          files = lib.filter (f: f.enable) (lib.attrValues hm.home.file);
          linked =
            p:
            lib.any (
              f:
              f.target == p
              || (
                f.recursive
                && lib.hasPrefix "${f.target}/" p
                && lib.pathExists (f.source + "/${lib.removePrefix "${f.target}/" p}") # path + string: no store copy
              )
            ) files;
          missing = lib.filter (p: !linked p) (lib.unique paths);
        in
        if missing == [ ] then
          pkgs.emptyFile
        else
          throw "${name}: claude settings reference unlinked ~/${lib.concatStringsSep ", ~/" missing}";

      nvimCheck =
        name: packs: dirs:
        let
          nvim = ../features/neovim/nvim;
          plugins = import ../features/neovim/_plugins.nix pkgs;
        in
        pkgs.runCommand "neovim-${name}-check" { nativeBuildInputs = [ pkgs.neovim-unwrapped ]; } ''
          export HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR/config XDG_DATA_HOME=$TMPDIR/data
          export XDG_STATE_HOME=$TMPDIR/state XDG_CACHE_HOME=$TMPDIR/cache
          mkdir -p $XDG_CONFIG_HOME/nvim/lua $XDG_DATA_HOME/nvim/site/pack
          ln -s ${nvim}/init.lua $XDG_CONFIG_HOME/nvim/init.lua
          for d in config util ${toString dirs}; do ln -s ${nvim}/lua/$d $XDG_CONFIG_HOME/nvim/lua/$d; done
          ${lib.concatMapStrings (p: ''
            mkdir -p $XDG_DATA_HOME/nvim/site/pack/nix-${p}
            ln -s ${plugins.${p}} $XDG_DATA_HOME/nvim/site/pack/nix-${p}/start
          '') packs}
          nvim --headless -u $XDG_CONFIG_HOME/nvim/init.lua -l ${../features/neovim/tests/${name}_test.lua}
          touch $out
        '';
    in
    {
      checks =
        lib.mapAttrs' (n: c: lib.nameValuePair "host-${n}" (check n c)) hosts
        // lib.mapAttrs' (n: c: lib.nameValuePair "claude-${n}" (claudeCheck n c)) claudeHosts
        // {
          # The shared nvim config starts offline with only the shared nixpkgs plugins, and
          # the IDE layer on top with its own.
          neovim-shared = nvimCheck "shared" [ "shared" ] [ ];
          neovim-ide =
            nvimCheck "ide"
              [
                "shared"
                "ide"
              ]
              [ "ide" ];
        };
    };
}
