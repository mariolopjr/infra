# One palette (_palette.nix) and wallpaper from Limine to the shell: Limine menu, console
# (incl. the initrd LUKS prompt), plymouth, noctalia-greeter and noctalia.
let
  palette = import ./_palette.nix;
  c = palette.dark;
  hex = s: builtins.substring 1 6 s; # "#rrggbb" -> "rrggbb"
  ansi =
    set:
    map (n: set.${n}) [
      "black"
      "red"
      "green"
      "yellow"
      "blue"
      "magenta"
      "cyan"
      "white"
    ];
  terminal = map hex (ansi c.terminal.normal);
  terminalBright = map hex (ansi c.terminal.bright);
  wallpaper = pkgs: pkgs.nixos-artwork.wallpapers.catppuccin-macchiato.gnomeFilePath;
in
{
  den.aspects.desktop.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      boot.loader.limine.style = {
        wallpapers = [ (wallpaper pkgs) ];
        wallpaperStyle = "stretched";
        backdrop = hex c.surface;
        interface = {
          branding = config.networking.hostName;
          brandingColor = hex c.primary;
          helpColor = hex c.secondary;
          helpColorBright = hex c.tertiary;
        };
        graphicalTerminal = {
          foreground = hex c.on_surface;
          background = "30${hex c.surface}"; # TT is transparency: 30 = mostly opaque
          brightForeground = hex c.on_surface;
          brightBackground = hex c.surface_container;
          palette = lib.concatStringsSep ";" terminal;
          brightPalette = lib.concatStringsSep ";" terminalBright;
        };
      };

      # VT colors via kernel params, so the initrd LUKS prompt matches too. Color 0 is the
      # VT background and 7 its default text.
      console.colors = [
        (hex c.surface)
      ]
      ++ lib.sublist 1 6 terminal
      ++ [ (hex c.on_surface) ]
      ++ terminalBright;

      services.displayManager.noctalia-greeter.settings.appearance = {
        scheme = "Synced";
        theme_mode = "dark";
        # Greeter still uses the pre-5.5 role names.
        palette = {
          inherit (c)
            primary
            on_primary
            secondary
            on_secondary
            tertiary
            on_tertiary
            error
            on_error
            surface
            on_surface
            on_surface_variant
            shadow
            hover
            on_hover
            ;
          surface_variant = c.surface_container;
          outline = c.outline_variant;
        };
        wallpaper = {
          path = wallpaper pkgs;
          fill_mode = "crop";
        };
      };

      # Plymouth: its spinner theme (two-step module, no script interpreter) on the palette
      # surface, with noctalia's owl recolored from its own colors to the palette.
      boot.plymouth = {
        enable = true;
        theme = "noctalia";
        themePackages = [
          (pkgs.runCommand "plymouth-theme-noctalia" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
            d=$out/share/plymouth/themes/noctalia
            spinner=${config.boot.plymouth.package}/share/plymouth/themes/spinner
            mkdir -p $d
            cp $spinner/*.png $d/
            sed -e 's/#fff59b/${c.primary}/gI' -e 's/#a9aefe/${c.secondary}/gI' \
              -e 's/#0e0e43/${c.shadow}/gI' -e 's/#f3edf7/${c.on_surface}/gI' \
              ${config.programs.noctalia.package.src}/assets/noctalia.svg > logo.svg
            rsvg-convert -w 192 logo.svg -o $d/watermark.png
            sed -E -e '/^Name\[/d' \
              -e 's|^Name=.*|Name=Noctalia|' \
              -e "s|^ImageDir=.*|ImageDir=$d|" \
              -e 's/^(Background(Start|End)Color)=.*/\1=0x${hex c.surface}/' \
              -e 's|^WatermarkVerticalAlignment=.*|WatermarkVerticalAlignment=.4|' \
              -e 's/^(Dialog|Title)VerticalAlignment=.*/\1VerticalAlignment=.65/' \
              -e 's|^VerticalAlignment=.*|VerticalAlignment=.8|' \
              $spinner/spinner.plymouth > $d/noctalia.plymouth
          '')
        ];
      };
    };

  # Noctalia reads every *.toml in ~/.config/noctalia; GUI changes go to
  # ~/.local/state/noctalia/settings.toml and win over these.
  den.aspects.mario.homeManager =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      xdg.configFile."noctalia/palettes/${palette.name}.json".text = builtins.toJSON {
        version = 2;
        inherit (palette) dark;
      };
      # 12-hour clock: plain %-specs go through strftime, so %-I drops the leading zero.
      xdg.configFile."noctalia/time.toml".text = ''
        [shell]
        time_format = "%-I:%M %p"

        [calendar]
        event_time_format = "%-I:%M %p"

        [widget.clock]
        format = "%-I:%M %p"

        [bar.main]
        scale = 1.15
        thickness = 40
      '';
      xdg.configFile."noctalia/theme.toml".source = (pkgs.formats.toml { }).generate "theme.toml" {
        theme = {
          mode = "dark";
          source = "custom";
          custom_palette = palette.name;
        };
        wallpaper.default.path = wallpaper pkgs;
      };
      # Sets XCURSOR_THEME/SIZE, which umbriel reads at session start.
      home.pointerCursor = {
        enable = true;
        package = pkgs.catppuccin-cursors.macchiatoMauve;
        name = "catppuccin-macchiato-mauve-cursors";
        size = 32;
        gtk.enable = true;
      };
    };
}
