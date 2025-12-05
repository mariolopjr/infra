{
  infra.neovim =
    _:
    let
      wkGroup = lhs: group: {
        "@1" = lhs;
        inherit group;
        mode = [
          "n"
          "v"
        ];
      };
    in
    {
      homeManager.programs.nvf = {
        settings.vim = {
          binds.whichKey = {
            enable = true;

            setupOpts = {
              preset = "helix";
              spec = [
                (wkGroup "<leader>d" "debug")
                (wkGroup "<leader>f" "files")
                (wkGroup "<leader>g" "git")
                (wkGroup "<leader>l" "lsp")
                (wkGroup "<leader>s" "search")
                (wkGroup "<leader>t" "text")
                (wkGroup "<leader><tab>" "tabs")
              ];
            };
          };
        };
      };
    };
}
