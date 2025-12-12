{
  infra.tmux = _: {
    homeManager =
      { pkgs, ... }:
      {
        programs.tmux = {
          enable = true;

          prefix = "C-a";
          keyMode = "vi";
          escapeTime = 5;
          newSession = true;

          tmuxp.enable = true;

          plugins = with pkgs.tmuxPlugins; [
            {
              plugin = fingers;
            }
            {
              plugin = mkTmuxPlugin {
                pluginName = "tmux-smart-splits";
                rtpFilePath = "smart-splits.tmux";
                version = "2.0.5";
                src = pkgs.fetchFromGitHub {
                  owner = "mrjones2014";
                  repo = "smart-splits.nvim";
                  rev = "ebb1375cda434c7a075986e1724fa53d0c754e8f";
                  sha256 = "sha256-EqnSGTyADvIpHxN3jZxwetENdqv/XUossUzrEvLHHMk=";
                };
              };
            }
          ];

          extraConfig = ''
            # split panes using | and -
            bind | split-window -h
            bind - split-window -v
            unbind '"'
            unbind %

            set-option -g allow-rename off
            set-option -g set-clipboard external

            # disable bell support
            set -g visual-activity off
            set -g visual-bell off
            set -g visual-silence off
            setw -g monitor-activity off
            set -g bell-action none

            # clear it all
            # TODO: figure out how to actually send Super-k to terminal
            # bind k send-keys -R \; send-keys Super-k \; clear-history
            bind k send-keys -R \; clear-history \; send-keys Enter

            # statusline
            set-option -g status-position top
            set -g status-left '#[fg=#{@thm_crust},bg=#{@thm_teal}] #S '

            bind r source-file ~/.config/tmux/tmux.conf
          '';
        };
      };
  };
}
