{
  infra.cooler-control = _: {
    nixos =
      { pkgs, ... }:
      {
        programs.coolercontrol = {
          enable = true;
        };

        environment.systemPackages = [
          pkgs.lm_sensors
        ];
      };
  };
}
