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
      claudeHosts = ofSystem (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations);
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
    in
    {
      checks =
        lib.mapAttrs' (n: c: lib.nameValuePair "host-${n}" (check n c)) hosts
        // lib.mapAttrs' (n: c: lib.nameValuePair "claude-${n}" (claudeCheck n c)) claudeHosts
        // {
          # check if vim.pack.add sources and lockfile list the same packages
          neovim =
            let
              nvim = ./features/neovim/nvim;
              srcs =
                f:
                map lib.head (
                  lib.filter lib.isList (
                    builtins.split "\"(https://github.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)\"" (builtins.readFile f)
                  )
                );
              added = lib.unique (
                lib.concatMap srcs (lib.filter (lib.hasSuffix ".lua") (lib.filesystem.listFilesRecursive nvim))
              );
              lock = nvim + "/nvim-pack-lock.json";
              locked = lib.optionals (builtins.pathExists lock) (
                lib.mapAttrsToList (_: p: p.src) (builtins.fromJSON (builtins.readFile lock)).plugins
              );
              failed = lib.filter (x: !x.ok) [
                {
                  ok = added != [ ] && lib.sort lib.lessThan added == lib.sort lib.lessThan locked;
                  msg = "vim.pack.add sources and nvim-pack-lock.json differ";
                }
              ];
            in
            if failed == [ ] then
              pkgs.emptyFile
            else
              throw "neovim: ${lib.concatMapStringsSep "; " (x: x.msg) failed}";
        };
    };
}
