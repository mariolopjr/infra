# LAN-only host: inbound accepted from the LAN only, outbound dropped except to the LAN and the
# blocks below. DNS and DHCP must come from the router (a LAN address).
{
  den.aspects.egress.nixos =
    { lib, ... }:
    let
      lan4 = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "169.254.0.0/16"
      ];
      lan6 = [
        "fe80::/10"
        "fc00::/7"
      ];
      allow4 = lan4 ++ [
        "224.0.0.0/4" # multicast: mDNS, SSDP
        "255.255.255.255" # DHCP
        "17.0.0.0/8" # Apple
      ];
      allow6 = lan6 ++ [
        "ff00::/8" # multicast
        "2620:149::/32" # Apple
        "2a01:b740::/32" # Apple
      ];
      set = lib.concatStringsSep ", ";
    in
    {
      networking.nftables.enable = true;
      # HomeKit opens data-stream and RTP ports at random, so the LAN gets every port.
      networking.firewall.extraInputRules = ''
        ip saddr { ${set lan4} } accept
        ip6 saddr { ${set lan6} } accept
      '';
      networking.nftables.tables.egress = {
        family = "inet";
        content = ''
          chain output {
            type filter hook output priority filter; policy drop;
            oifname "lo" accept
            ct state established,related accept
            ip daddr { ${set allow4} } accept
            ip6 daddr { ${set allow6} } accept
            meta l4proto ipv6-icmp accept # neighbor discovery
            limit rate 10/minute log prefix "egress-drop: "
          }
        '';
      };
      networking.timeServers = [ "time.apple.com" ]; # resolves into 17.0.0.0/8
    };
}
