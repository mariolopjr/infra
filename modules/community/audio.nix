{
  infra.audio.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.playerctl
      ];
    };
}
