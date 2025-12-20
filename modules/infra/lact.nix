{
  infra.lact = _: {
    nixos = {
      services.lact.enable = true;
      environment = {
        etc = {
          "lact/config.yaml" =
            let
              # in percent
              idle = "0.35";
              operating = "0.45";
            in
            {
              text = ''
                version: 5
                daemon:
                  log_level: error
                  admin_group: wheel
                  disable_clocks_cleanup: false
                apply_settings_timer: 0
                gpus:
                  10DE:2C02-10DE:2095-0000:01:00.0:
                    fan_control_enabled: true
                    fan_control_settings:
                      mode: curve
                      static_speed: 0.5
                      temperature_key: junction
                      interval_ms: 500
                      curve:
                        20: ${idle}
                        79: ${idle}
                        80: ${operating}
                        94: ${operating}
                        95: 0.6
                        100: 0.9
                      spindown_delay_ms: 30000
                      change_threshold: 2
                    power_cap: 390.0
                    gpu_clock_offsets:
                      0: 350
                    mem_clock_offsets:
                      0: 500
                current_profile: null
                auto_switch_profiles: false
              '';
              mode = "0644";
            };
        };
      };
    };
  };
}
