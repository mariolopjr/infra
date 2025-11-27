{
  infra.networkmanager.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.networkmanager
      ];
    };
}
