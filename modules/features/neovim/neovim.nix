{
  # Every host: the editor, shared settings and the nixpkgs plugins (no network needed).
  den.aspects.mario.homeManager =
    { pkgs, ... }:
    let
      languages = [
        "bash"
        "go"
        "json"
        "nix"
        "rust"
        "toml"
        "yaml"
      ];
      queries = "${pkgs.vimPlugins.nvim-treesitter}/runtime/queries";
      treesitter = pkgs.linkFarm "nvim-treesitter-site" (
        builtins.concatMap (l: [
          {
            name = "parser/${l}.so";
            path = "${pkgs.vimPlugins.nvim-treesitter-parsers.${l}}/parser/${l}.so";
          }
          {
            name = "queries/${l}";
            path = "${queries}/${l}";
          }
        ]) languages
      );
    in
    {
      home.packages = [
        pkgs.neovim-unwrapped
        pkgs.git
        pkgs.ripgrep # snacks picker
        pkgs.fd
      ];
      home.sessionVariables.EDITOR = "nvim";

      xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
      xdg.configFile."nvim/lua/config".source = ./nvim/lua/config;
      xdg.configFile."nvim/lua/util".source = ./nvim/lua/util;

      xdg.dataFile."nvim/site/pack/nix-shared/start".source = (import ./_plugins.nix pkgs).shared;
      xdg.dataFile."nvim/site/parser".source = "${treesitter}/parser";
      xdg.dataFile."nvim/site/queries".source = "${treesitter}/queries";
    };

  # IDE layer: formatters, language servers and the plugins for them.
  den.aspects.dev.provides.to-users.homeManager =
    { lib, pkgs, ... }:
    {
      home.packages = [
        pkgs.nil
        pkgs.nixd
        pkgs.nixfmt
      ]
      ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.wl-clipboard; # clipboard provider for unnamedplus
      xdg.configFile."nvim/lua/ide".source = ./nvim/lua/ide;
      xdg.dataFile."nvim/site/pack/nix-ide/start".source = (import ./_plugins.nix pkgs).ide;
    };
}
