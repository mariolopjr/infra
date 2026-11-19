# Homebridge with UniFi Protect cameras for HomeKit Secure Video. The Protect controller address
# and login go in through the UI (port 8581) and live in /var/lib/homebridge/config.json.
{
  den.aspects.homebridge.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.homebridge;
      protect = pkgs.callPackage ./_unifi-protect.nix { };
    in
    {
      services.homebridge.enable = true;
      # The UI's plugin installer needs npm, which the egress allowlist blocks; plugins come from Nix.
      # mkAfter: the module's preStart creates pluginPath.
      systemd.services.homebridge.preStart = lib.mkAfter ''
        ln -sfn ${protect}/lib/node_modules/homebridge-unifi-protect ${cfg.pluginPath}/homebridge-unifi-protect
      '';
    };
}
