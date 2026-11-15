# OpenSnitch: per-process application firewall (eBPF + nftables).
# Rules in services.opensnitch.rules are symlinked into /var/lib/opensnitch/rules each start.
{ inputs, ... }:
{
  den.aspects.desktop.nixos =
    { lib, pkgs, ... }:
    {
      services.opensnitch = {
        enable = true;
        settings.DefaultAction = "allow";
        # The lists loader only globs `<dir>/*.*`, so the file needs an extension.
        rules.pgl-blocklist = {
          name = "pgl-blocklist";
          enabled = true;
          precedence = true; # priority over allow rules
          action = "reject";
          duration = "always";
          operator = {
            type = "lists";
            operand = "lists.domains";
            data = "${pkgs.linkFarm "opensnitch-blocklists" { "pgl.txt" = inputs.pgl-blocklist; }}";
          };
        };
      };

      systemd.user.services.opensnitch-ui = {
        description = "OpenSnitch connection prompts";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          ExecStart = "${lib.getExe' pkgs.opensnitch-ui "opensnitch-ui"} --background";
        };
      };

      preservation.preserveAt."/persist" = {
        directories = [ "/var/lib/opensnitch" ];
        users.mario.directories = [ ".config/opensnitch" ];
      };
    };
}
