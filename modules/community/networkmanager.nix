{
  infra.networkmanager.nixos =
    { pkgs, ... }:
    {
      networking.networkmanager.enable = true;
      # don't delay system or rebuilds due to waiting for online
      systemd.services.NetworkManager-wait-online.enable = false;
      # disable network-manager-applet from starting
      systemd.services."network-manager-applet".enable = false;

      environment.systemPackages = [
        pkgs.networkmanager
      ];
    };
}
