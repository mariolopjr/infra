# nushell as login shell, with starship, zoxide, carapace and an ssh agent setup
{ lib, ... }:
{
  den.aspects.shell = {
    homeManager =
      { pkgs, lib, ... }:
      {
        programs.zoxide.enable = true;
        programs.starship.enable = true;
        programs.bat.enable = true;
        programs.fzf = {
          enable = true;
          # highgarden's own nixpkgs can lag behind the version the nushell integration needs
          enableNushellIntegration = lib.versionAtLeast pkgs.fzf.version "0.73.0";
        };
        programs.bottom.enable = true;
        programs.carapace.enable = true;
        # macOS: Apple's launchd ssh-agent and /usr/bin/ssh are able to UseKeychain.
        # Linux: pam_ssh_add, see desktop.nix.
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*" = {
            AddKeysToAgent = "yes";
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { UseKeychain = "yes"; };
        };
        # preload keychain-stored keys
        launchd.agents.ssh-add-keychain = {
          enable = true;
          config = {
            ProgramArguments = [
              "/usr/bin/ssh-add"
              "--apple-load-keychain"
            ];
            RunAtLoad = true;
          };
        };
        programs.nushell.shellAliases = {
          c = "claude";
          gg = "lazygit";
          l = "ls";
          cl = "claude --continue";
          lla = "ls -la";
          v = "nvim";
          gcm = "git commit -m";
          gds = "git diff --stat";
          gpu = "git push origin (git_current_branch) --set-upstream";
          gpv = "git push --no-verify";
          gwtulo = "git worktree unlock"; # upstream typo: `unlockbanner`
          "gp!" = "git push --force-with-lease";
          gpo = "git push origin";
          "gpo!" = "git push --force-with-lease origin";
          gcom = "git checkout (git_main_branch)";
          gll = "git pull origin";
          glr = "git pull --rebase";
          gban = "git branch -a -v --no-merged";
          gmt = "git mergetool --no-prompt";
          "gcs!" = "git commit -S --amend";
        };
        programs.nushell.enable = true;
        # sshd sessions and rex panes (rex.service starts before login): reuse the agent
        # pam_ssh_add started at the desktop login
        programs.nushell.extraEnv = ''
          if ($env.SSH_AUTH_SOCK? == null) {
            let sock = (systemctl --user show-environment | lines | parse "{k}={v}" | where k == SSH_AUTH_SOCK | get v.0?)
            if $sock != null { $env.SSH_AUTH_SOCK = $sock }
          }
        '';
        # nix-index ships command-not-found hooks for bash/zsh/fish only; same lookup for nushell.
        programs.nushell.extraConfig = ''
          use ${pkgs.nu_scripts}/share/nu_scripts/aliases/git/git-aliases.nu *

          $env.config.hooks.command_not_found = {|cmd|
            if (which nix-locate | is-empty) { return null }
            let pkgs = (nix-locate --minimal --no-group --type x --type s --whole-name --at-root $"/bin/($cmd)" | lines | str replace -r '\.out$' "")
            if ($pkgs | is-empty) { return null }
            let list = ($pkgs | each {|p| $"  nixpkgs#($p)" } | str join "\n")
            $"($cmd) is provided by:\n($list)\nRun it once with: , ($cmd)"
          }

          # small reminder when a typed command matches an alias expansion
          $env.config.hooks.pre_execution = ($env.config.hooks.pre_execution? | default [] | append {||
            let cmd = (commandline | str trim)
            let hits = (scope aliases | where {|a| $cmd == $a.expansion or ($cmd | str starts-with $"($a.expansion) ")})
            if ($hits | is-not-empty) {
              let a = ($hits | sort-by {|h| $h.expansion | str length} --reverse | first)
              print $"(ansi yellow)alias tip:(ansi reset) ($a.name) = ($a.expansion)"
            }
          })
        '';
      };

    # NixOS only: on darwin the login shell stays the account's own.
    provides.to-hosts =
      { host, user, ... }:
      lib.optionalAttrs (host.class == "nixos") {
        nixos =
          { pkgs, ... }:
          {
            users.users.${user.userName}.shell = pkgs.nushell;
          };
      };
  };
}
