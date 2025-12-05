{ inputs, ... }:
let
  inherit (inputs.nvf) lib;
  inherit (lib.nvim.binds) mkKeymap;
in
{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        notes.todo-comments.enable = true;

        keymaps = [
          # general
          (mkKeymap [ "n" "v" ] "]t"
            # lua
            ''
              function() require("todo-comments").jump_next() end
            ''
            {
              desc = "next todo";
              lua = true;
            }
          )
          (mkKeymap [ "n" "v" ] "[t"
            # lua
            ''
              function() require("todo-comments").jump_prev() end
            ''
            {
              desc = "previous todo";
              lua = true;
            }
          )
        ];
      };
    };
  };
}
