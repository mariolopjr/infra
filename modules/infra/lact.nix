{
  infra.lact = _: {
    nixos = {
      services.lact = {
        enable = true;
        settings = {
          version = 5;
          daemon = {
            log_level = "error";
            admin_group = "wheel";
            disable_clocks_cleanup = false;
          };
          apply_settings_timer = 0;
          gpus."10DE:2C02-10DE:2095-0000:01:00.0" = {
            fan_control_enabled = false;
            power_cap = 390.0;
            gpu_clock_offsets = {
              "0" = 350;
            };
            mem_clock_offsets = {
              "0" = 500;
            };
          };
          current_profile = null;
          auto_switch_profiles = false;
        };
      };
    };
  };
}
