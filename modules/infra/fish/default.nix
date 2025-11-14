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
