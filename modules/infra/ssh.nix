{
  infra.ssh = _: {
    nixos = {
      services.openssh = {
        enable = true;
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
