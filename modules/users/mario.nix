{ den, ... }:
let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAipRk9CK71BwC7DtnYAsMX5CsuCbnq03YaOL7ZKX+bn dragonstone"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaGF5WxANyrUZqR65w31DvRzK6n9IaGCjpIT3kxozaV winterfell"
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
        services.ssh-agent.enable = true;
        programs.ssh = {
          enable = true;
          settings."*".AddKeysToAgent = "yes";
        };
        # git gpg.ssh.allowedSignersFile
        home.file.".ssh/allowed_signers".text = lib.concatMapStrings (k: "* ${k}\n") sshKeys;
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
          pkgs.lazygit
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
        '';
      };

    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        # Password is set by the installer (passwd via nixos-enter).
        users.users.mario.shell = pkgs.nushell;
        users.users.mario.openssh.authorizedKeys.keys = sshKeys;
      };
  };
}
