{
  infra.limine.nixos = {
    boot.loader.limine = {
      enable = true;
      enableEditor = true;
      maxGenerations = 20;
      # efiInstallAsRemovable = true;
      # secureBoot.enable = true;
      # secureBoot.configFile = sbctlConfig;
    };
  };
}
