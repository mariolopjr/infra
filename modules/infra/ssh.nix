{ ... }:
let
  allowedPubkeys = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAipRk9CK71BwC7DtnYAsMX5CsuCbnq03YaOL7ZKX+bn
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhF7/5agjGzrAiS7eOH+tY5GhqdLKqbCuvGwkbR0lyr
  '';
in
{
  infra.ssh = _: {
    nixos = {
      services.openssh = {
        enable = true;

        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
    };
    homeManager = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        # TODO: add servers that have wezterm TERM support
        matchBlocks."*" = {
          forwardAgent = false;
          addKeysToAgent = "yes";
          userKnownHostsFile = "~/.ssh/known_hosts";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
      };
    };
  };
}
