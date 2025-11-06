{
  infra.nix-direnv = _: {
    homeManager = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableFishIntegration = true;
      };
    };
  };
}
