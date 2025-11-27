{
  infra.networkmanager.nixos =
    { pkgs, ... }:
    {
      networking.networkmanager.enable = true;

      environment.systemPackages = [
        pkgs.networkmanager
      ];
    };
}
