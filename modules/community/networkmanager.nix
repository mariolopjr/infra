{
  infra.networkmanager.nixos =
    { pkgs, ... }:
    {
      networking.networkmanager.enable = true;
      # don't delay system or rebuilds due to waiting for online
      systemd.services.NetworkManager-wait-online.enable = false;

      environment.systemPackages = [
        pkgs.networkmanager
      ];
    };
}
