# Plugin sets linked to pack/nix-<set>/start: shared on every host, ide with the dev aspect.
pkgs:
builtins.mapAttrs
  (
    set: plugins:
    pkgs.linkFarm "nvim-plugins-${set}" (
      map (p: {
        name = p.pname;
        path = p;
      }) plugins
    )
  )
  (
    with pkgs.vimPlugins;
    {
      shared = [
        catppuccin-nvim
        mini-nvim
        snacks-nvim
        which-key-nvim
        flash-nvim
        smart-splits-nvim
      ];
      ide = [
        conform-nvim
        nvim-lspconfig
        lazydev-nvim
      ];
    }
  )
