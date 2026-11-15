# GPU (LACT) and case fan (CoolerControl) control
{
  den.aspects.fans.nixos =
    { pkgs, ... }:
    {
      # LACT factory defaults. Per-GPU settings (power cap, clocks, fan curve) key on the
      # exact PCI id from `lact cli list-gpus`.
      services.lact = {
        enable = true;
        settings = {
          version = 7;
          daemon = {
            log_level = "info";
            admin_group = "wheel";
            disable_clocks_cleanup = false;
          };
          apply_settings_timer = 5;
        };
      };

      # CoolerControl factory config
      programs.coolercontrol.enable = true;
      environment.etc."coolercontrol/config.toml" = {
        mode = "0644";
        source = (pkgs.formats.toml { }).generate "coolercontrol.toml" {
          devices = { };
          legacy690 = { };
          device-settings = { };
          profiles = [
            {
              uid = "0";
              name = "Unmanaged";
              p_type = "Default";
              function = "0";
            }
          ];
          functions = [
            {
              uid = "0";
              name = "Default Function";
              f_type = "Identity";
            }
          ];
          settings = {
            apply_on_boot = true;
            liquidctl_integration = true;
            hide_duplicate_devices = true;
            no_init = false;
            startup_delay = 2;
            thinkpad_full_speed = false;
            compress_payload = true;
            drivetemp_suspend = false;
          };
        };
      };
    };
}
