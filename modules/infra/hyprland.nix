{ inputs, ... }:
{
  flake-file.inputs = {
    hyprland.url = "github:hyprwm/hyprland";
  };

  infra.hyprland = {
    nixos =
      { pkgs, ... }:
      {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          withUWSM = true;

          package = inputs.hyprland.packages.${pkgs.system}.default;
          portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
        };
      };
  };
}
