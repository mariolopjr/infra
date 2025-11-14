{
  infra.ssh = _: {
    nixos = {
      services.openssh = {
        enable = true;

        settings = {
          PermitRootLogin = "no";
          # TODO: uncomment
          # PasswordAuthentication = false;
          # KbdInteractiveAuthentication = false;
        };
      };
    };
    homeManager = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        # TODO: add servers that have ghostty TERM support
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
