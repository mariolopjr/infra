{
  infra.neovim = _: {
    homeManager = {
      programs.nvf = {
        settings = {
          vim = {
            utility.snacks-nvim = {
              enable = true;
              setupOpts = {
                bigfile.enable = true;

                dashboard = {
                  enabled = true;
                  sections = [
                    { section = "header"; }
                    {
                      icon = " ";
                      title = "Keymaps";
                      section = "keys";
                      indent = 2;
                      padding = 1;
                    }
                    {
                      icon = " ";
                      title = "Projects";
                      section = "projects";
                      indent = 2;
                      padding = 1;
                    }
                    {
                      icon = " ";
                      title = "Recent Files";
                      section = "recent_files";
                      indent = 2;
                      padding = 1;
                    }
                    # TODO: recreate snacks startup, with using stats and plugins loaded via nvf
                    # { section = "startup"; }
                  ];
                };

                explorer.enable = true;
                indent.enable = true;
                input.enable = true;
                notifier.enable = true;

                image = {
                  enable = true;
                  math = false;
                };

                picker = {
                  matcher = {
                    frecency = true;
                  };

                  win.input.keys = {
                    "<Esc>" = {
                      "@1" = "close";
                      mode = [
                        "n"
                        "i"
                      ];
                    };
                    # scroll like lazygit
                    "J" = {
                      "@1" = "preview_scroll_down";
                      mode = [
                        "n"
                        "i"
                      ];
                    };
                    "K" = {
                      "@1" = "preview_scroll_up";
                      mode = [
                        "n"
                        "i"
                      ];
                    };
                    "H" = {
                      "@1" = "preview_scroll_left";
                      mode = [
                        "n"
                        "i"
                      ];
                    };
                    "L" = {
                      "@1" = "preview_scroll_right";
                      mode = [
                        "n"
                        "i"
                      ];
                    };
                  };
                };

                quickfile.enable = true;
                scroll.enable = true;
                statuscolumn.enabled = true;
                terminal.enabled = false;
                words.enable = true;
              };
            };
          };
        };
      };
    };
  };
}
