{ den, ... }:
let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAipRk9CK71BwC7DtnYAsMX5CsuCbnq03YaOL7ZKX+bn dragonstone"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaGF5WxANyrUZqR65w31DvRzK6n9IaGCjpIT3kxozaV winterfell"
  ];
  # login only
  phoneKeys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBImMg0zbBLjw6D9UBA7LHvtPX8PqJs3tYaMkWreh+vLgQlJS5f3Mwaw43nRxJ17TV/yRs+MgdN9qknmRrkgevr0= rex@iPhone"
  ];
in
{
  den.aspects.mario = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
    ];

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.zoxide.enable = true;
        programs.starship.enable = true;
        programs.bat.enable = true;
        programs.fzf.enable = true;
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
        # git gpg.ssh.allowedSignersFile
        home.file.".ssh/allowed_signers".text = lib.concatMapStrings (k: "* ${k}\n") sshKeys;
        # Intermediate build artifacts per workspace under ~/.cargo
        home.file.".cargo/config.toml".text = ''
          [build]
          build-dir = "{cargo-cache-home}/build/{workspace-path-hash}"
        '';
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        home.packages = [
          pkgs.age
          pkgs.claude-code
          pkgs.devenv
          pkgs.f3
          pkgs.just
        ];
        programs.nushell.shellAliases = {
          c = "claude";
          gg = "lazygit";
          l = "ls";
          cl = "claude --continue";
          lla = "ls -la";
          v = "nvim";
          rebuild = "just -f ~/.config/infra/justfile rebuild";
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

    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        # Password is set by the installer (passwd via nixos-enter).
        users.users.mario.shell = pkgs.nushell;
      };
    provides.to-hosts.os.users.users.mario.openssh.authorizedKeys.keys = sshKeys ++ phoneKeys;
  };
}
