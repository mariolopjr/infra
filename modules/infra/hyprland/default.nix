{ inputs, ... }:
{
  flake-file.inputs = {
    hyprland.url = "github:hyprwm/hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
      inputs = {
        hyprutils.follows = "hyprland/hyprutils";
        hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };
  };

  infra.hyprland = _: {
    nixos =
      { pkgs, ... }:
      {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          #withUWSM = true;

          package = inputs.hyprland.packages.${pkgs.system}.default;
          portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
        };

        # tell Electron/Chromium to run on Wayland
        environment.sessionVariables.NIXOS_OZONE_WL = "1";
      };

    homeManager =
      {
        config,
        pkgs,
        ...
      }:
      let
        cfg = config.wayland.windowManager.hyprland;
      in
      {
        wayland.windowManager.hyprland = {
          enable = true;
          systemd.enable = false;

          settings.permission = builtins.map (
            plugin: plugin + "/lib/lib${plugin.pname}.so, plugin, allow"
          ) cfg.plugins;
        };

        services.network-manager-applet.enable = true;

        home.packages =
          let
            inherit (inputs.hyprpicker.packages.${pkgs.system}) hyprpicker;
          in
          builtins.attrValues {
            inherit (pkgs)
              brightnessctl
              pwvucontrol
              satty
              wl-clipboard
              ;
          }
          ++ [
            hyprpicker
            (inputs.hyprland-contrib.packages.${pkgs.system}.grimblast.override { inherit hyprpicker; })
          ];
      };
  };
}
