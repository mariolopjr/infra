{
  infra.fonts = _: {
    nixos =
      { pkgs, ... }:
      {
        fonts.packages = with pkgs.nerd-fonts; [
          jetbrains-mono
        ];
      };
  };
}
