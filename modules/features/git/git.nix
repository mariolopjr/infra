{
  den.aspects.mario.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.delta # core.pager
        pkgs.difftastic # diff.tool
        pkgs.git-lfs # filter.lfs
        # gpg.ssh.program: non-nushell callers (Claude and its subagents) lack SSH_AUTH_SOCK,
        # so signing fell back to the passphrase key. Reuse the agent from the systemd user env.
        (pkgs.writeShellScriptBin "git-ssh-sign" ''
          if [ -z "''${SSH_AUTH_SOCK:-}" ] && command -v systemctl >/dev/null; then
            sock=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^SSH_AUTH_SOCK=//p')
            [ -n "$sock" ] && export SSH_AUTH_SOCK="$sock"
          fi
          exec ssh-keygen "$@"
        '')
      ];
      xdg.configFile."git/config".source = ./config;
      xdg.configFile."git/ignore".source = ./ignore;
    };
}
