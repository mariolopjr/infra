{
  infra.fish =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          programs.fish.enable = true;
          users.users.${user.userName}.shell = pkgs.fish;
        };

      homeManager =
        { lib, pkgs, ... }:
        {
          programs.fzf.enable = true;
          programs.fzf.enableFishIntegration = true;

          home.packages = with pkgs; [
            microfetch
          ];

          programs.fish = {
            enable = true;

            interactiveShellInit =
              # fish
              ''
                fish_vi_key_bindings
                set fish_cursor_default block blink # normal mode
                set fish_cursor_insert line blink # insert mode
                set fish_cursor_replace_one underscore blink # replace mode
                set fish_cursor_replace underscore blink # replace mode
                set fish_cursor_visual block # visual mode

                set fish_cursor_external line # in commands

                set fish_greeting
              '';

            plugins =
              let
                fishPlugin = name: {
                  name = name.pname;
                  inherit (name) src;
                };
              in
              [
                # TODO: add the other fish plugins as nix packages
                (fishPlugin pkgs.fishPlugins.autopair)
                (fishPlugin pkgs.fishPlugins.done)
                # (fishPlugin pkgs.fishPlugins.fish-abbreviation-tips)
                (fishPlugin pkgs.fishPlugins.fzf-fish)
                # (fishPlugin pkgs.fishPlugins.puffer-fish)
                (fishPlugin pkgs.fishPlugins.tide)
              ];

            functions = {
              "__git.default_branch" = {
                body =
                  #fish
                  ''
                    command git rev-parse --git-dir &>/dev/null; or return
                    if set -l default_branch (command git config --get init.defaultBranch)
                      and command git show-ref -q --verify refs/heads/{$default_branch}
                      echo $default_branch
                    else if command git show-ref -q --verify refs/heads/main
                      echo main
                    else
                      echo master
                    end
                  '';
                description = "Use init.defaultBranch if it's set and exists, otherwise use main if it exists. Falls back to master";
              };
            };

            shellAbbrs = {
              d = "cd ~/dotfiles";

              l = "ls";
              la = "ls -a";
              ll = "ls -l";
              lla = "ls -la";

              # git abbreviations
              # credit: jhillyerd, https://github.com/jhillyerd/plugin-git
              g = "git";
              ga = "git add";
              gaa = "git add --all";
              gau = "git add --update";
              gapa = "git add --patch";
              gap = "git apply";
              gb = "git branch -vv";
              gba = "git branch -a -v";
              gban = "git branch -a -v --no-merged";
              gbd = "git branch -d";
              gbD = "git branch -D";
              ggsup = "git branch --set-upstream-to=origin/\(__git.current_branch\)";
              gbl = "git blame -b -w";
              gbs = "git bisect";
              gbsb = "git bisect bad";
              gbsg = "git bisect good";
              gbsr = "git bisect reset";
              gbss = "git bisect start";
              gc = "git commit -v";
              "gc!" = "git commit -v --amend";
              "gcn!" = "git commit -v --no-edit --amend";
              gca = "git commit -v -a";
              "gca!" = "git commit -v -a --amend";
              "gcan!" = "git commit -v -a --no-edit --amend";
              gcv = "git commit -v --no-verify";
              gcav = "git commit -a -v --no-verify";
              "gcav!" = "git commit -a -v --no-verify --amend";
              gcm = "git commit -m";
              gcam = "git commit -a -m";
              gcs = "git commit -S";
              gscam = "git commit -S -a -m";
              gcfx = "git commit --fixup";
              gcf = "git config --list";
              gcl = "git clone";
              gclean = "git clean -di";
              "gclean!" = "git clean -dfx";
              "gclean!!" = "git reset --hard; and = 'git clean -dfx'";
              gcount = "git shortlog -sn";
              gcp = "git cherry-pick";
              gcpa = "git cherry-pick --abort";
              gcpc = "git cherry-pick --continue";
              gd = "git diff";
              gdca = "git diff --cached";
              gds = "git diff --stat";
              gdsc = "git diff --stat --cached";
              gdt = "git diff-tree --no-commit-id --name-only -r";
              gdw = "git diff --word-diff";
              gdwc = "git diff --word-diff --cached";
              gdto = "git difftool";
              gdg = "git diff --no-ext-diff";
              gignore = "git update-index --assume-unchanged";
              gf = "git fetch";
              gfa = "git fetch --all --prune";
              gfm = "git fetch origin (__git.default_branch) --prune; and = 'git merge FETCH_HEAD'";
              gfo = "git fetch origin";
              gl = "git pull";
              ggl = "git pull origin \(__git.current_branch\)";
              gll = "git pull origin";
              glr = "git pull --rebase";
              glg = "git log --stat";
              glgg = "git log --graph";
              glgga = "git log --graph --decorate --all";
              glo = "git log --oneline --decorate --color";
              glog = "git log --oneline --decorate --color --graph";
              gloga = "git log --oneline --decorate --color --graph --all";
              glom = "git log --oneline --decorate --color \(__git.default_branch\)..";
              glod = "git log --oneline --decorate --color develop..";
              gloo = "git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short";
              gm = "git merge";
              gmt = "git mergetool --no-prompt";
              gmom = "git merge origin/\(__git.default_branch\)";
              gp = "git push";
              "gp!" = "git push --force-with-lease";
              gpo = "git push origin";
              "gpo!" = "git push --force-with-lease origin";
              gpv = "git push --no-verify";
              "gpv!" = "git push --no-verify --force-with-lease";
              ggp = "git push origin \(__git.current_branch\)";
              "ggp!" = "git push origin \(__git.current_branch\) --force-with-lease";
              gpu = "git push origin \(__git.current_branch\) --set-upstream";
              gpoat = "git push origin --all; and = 'git push origin --tags'";
              ggpnp = "git pull origin (__git.current_branch); and = 'git push origin (__git.current_branch)'";
              gr = "git remote -vv";
              gra = "git remote add";
              grb = "git rebase";
              grba = "git rebase --abort";
              grbc = "git rebase --continue";
              grbi = "git rebase --interactive";
              grbm = "git rebase \(__git.default_branch\)";
              grbmi = "git rebase \(__git.default_branch\) --interactive";
              grbmia = "git rebase \(__git.default_branch\) --interactive --autosquash";
              grbom = "git fetch origin (__git.default_branch); and = 'git rebase FETCH_HEAD'";
              grbomi = "git fetch origin (__git.default_branch); and = 'git rebase FETCH_HEAD --interactive'";
              grbomia = "git fetch origin (__git.default_branch); and = 'git rebase FETCH_HEAD --interactive --autosquash'";
              grbd = "git rebase develop";
              grbdi = "git rebase develop --interactive";
              grbdia = "git rebase develop --interactive --autosquash";
              grbs = "git rebase --skip";
              ggu = "git pull --rebase origin \(__git.current_branch\)";
              grev = "git revert";
              grh = "git reset";
              grhh = "git reset --hard";
              grhpa = "git reset --patch";
              grm = "git rm";
              grmc = "git rm --cached";
              grmv = "git remote rename";
              grpo = "git remote prune origin";
              grrm = "git remote remove";
              grs = "git restore";
              grset = "git remote set-url";
              grss = "git restore --source";
              grst = "git restore --staged";
              grup = "git remote update";
              grv = "git remote -v";
              gsh = "git show";
              gsd = "git svn dcommit";
              gsr = "git svn rebase";
              gsb = "git status -sb";
              gss = "git status -s";
              gst = "git status";
              gsta = "git stash";
              gstd = "git stash drop";
              gstl = "git stash list";
              gstp = "git stash pop";
              gsts = "git stash show --text";
              gsu = "git submodule update";
              gsur = "git submodule update --recursive";
              gsuri = "git submodule update --recursive --init";
              gts = "git tag -s";
              gtv = "git tag | sort -V";
              gsw = "git switch";
              gswc = "git switch --create";
              gunignore = "git update-index --no-assume-unchanged";
              gup = "git pull --rebase";
              gupv = "git pull --rebase -v";
              gupa = "git pull --rebase --autostash";
              gupav = "git pull --rebase --autostash -v";
              gwch = "git whatchanged -p --abbrev-commit --pretty=medium";

              # git checkout abbreviations
              gco = "git checkout";
              gcb = "git checkout -b";
              gcod = "git checkout develop";
              gcom = "git checkout \(__git.default_branch\)";

              # git flow abbreviations
              gfb = "git flow bugfix";
              gff = "git flow feature";
              gfr = "git flow release";
              gfh = "git flow hotfix";
              gfs = "git flow support";

              gfbs = "git flow bugfix start";
              gffs = "git flow feature start";
              gfrs = "git flow release start";
              gfhs = "git flow hotfix start";
              gfss = "git flow support start";

              gfbt = "git flow bugfix track";
              gfft = "git flow feature track";
              gfrt = "git flow release track";
              gfht = "git flow hotfix track";
              gfst = "git flow support track";

              gfp = "git flow publish";

              # git worktree abbreviations
              gwt = "git worktree";
              gwta = "git worktree add";
              gwtls = "git worktree list";
              gwtlo = "git worktree lock";
              gwtmv = "git worktree move";
              gwtpr = "git worktree prune";
              gwtrm = "git worktree remove";
              gwtulo = "git worktree unlock";

              mkdev = {
                setCursor = "%";
                expansion = "nix flake new --template $NH_FLAKE#%";
              };
            };
          };

          home.activation.tide-configure =
            lib.hm.dag.entryAfter [ "writeBoundary" ]
              #bash
              ''
                ${pkgs.fish}/bin/fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Solid --prompt_connection_andor_frame_color=Darkest --prompt_spacing=Sparse --icons='Few icons' --transient=Yes"
              '';

        };
    };
}
