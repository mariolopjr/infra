{ inputs, ... }:
let
  inherit (inputs.nvf) lib;
  inherit (lib.nvim.binds) mkKeymap;
in
{
  infra.neovim = _: {
    homeManager.programs.nvf = {
      settings.vim = {
        utility.motion.hop = {
          enable = true;
          # mappings.hop = "<leader><leader>";
        };

        keymaps =
          let
            hopVars =
              #lua
              ''
                local hop = require("hop")
                local direction = require("hop.hint").HintDirection
              '';
          in
          [
            (mkKeymap [ "n" "v" ] "f"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_char1({
                    direction = direction.AFTER_CURSOR,
                    current_line_only = true,
                  })
                end
              ''
              {
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "F"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_char1({
                    direction = direction.BEFORE_CURSOR,
                    current_line_only = true,
                  })
                end
              ''
              {
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "t"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_char1({
                    direction = direction.AFTER_CURSOR,
                    current_line_only = true,
                    hint_offset = -1,
                  })
                end
              ''
              {
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "T"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_char1({
                    direction = direction.BEFORE_CURSOR,
                    current_line_only = true,
                    hint_offset = -1,
                  })
                end
              ''
              {
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader><leader>w"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_words({
                    direction = direction.AFTER_CURSOR,
                  })
                end
              ''
              {
                desc = "[ ] [ ] Hop to [W]ord After Cursor";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader><leader>b"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_words({
                    direction = direction.BEFORE_CURSOR,
                  })
                end
              ''
              {
                desc = "[ ] [ ] Hop to Word [B]efore Cursor";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader><leader>j"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_lines_skip_whitespace({
                    direction = direction.AFTER_CURSOR,
                  })
                end
              ''
              {
                desc = "[ ] [ ] [j] Hop to Line After Cursor";
                lua = true;
              }
            )
            (mkKeymap [ "n" "v" ] "<leader><leader>k"
              # lua
              ''
                function()
                  ${hopVars}
                  hop.hint_lines_skip_whitespace({
                    direction = direction.BEFORE_CURSOR,
                  })
                end
              ''
              {
                desc = "[ ] [ ] [l] Hop to Line Before Cursor";
                lua = true;
              }
            )
          ];
      };
    };
  };
}
