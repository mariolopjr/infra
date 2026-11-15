{
  den.aspects.mario.homeManager =
    { config, pkgs, ... }:
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
      xdg.configFile."nvim/lua".source = ./nvim/lua;
      xdg.configFile."nvim/nvim-pack-lock.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/infra/modules/features/neovim/nvim/nvim-pack-lock.json";

      xdg.dataFile."nvim/site/parser".source = "${treesitter}/parser";
      xdg.dataFile."nvim/site/queries".source = "${treesitter}/queries";
    };
}
