# GPU (LACT) and case fan (CoolerControl) control
{
  den.aspects.fans.nixos =
    { pkgs, ... }:
    let
      toml = pkgs.formats.toml { };
      # coolercontrold's device hashes
      nct6799 = "00a4da18625f56275c89e2fcd25a83c08c5ad3326452fa7e252fcc8a89c92493";
      rtx5080 = "034c2fb184a101865710c8258650caaaeade161075207cedb2f14e4168d8e6d2";
      cpu = "3145e1a42801faf9cf948df8c705afb4859f084c10a7e7c5e4efecb1e0167127";
      # Profile uids: device-settings and the Case mix reference them
      gpuProfile = "f7db5d77-811d-42d1-8fe1-7dba8b2415bb";
      cpuProfile = "10e5bad1-bd74-47e4-8795-b50a0e86d573";
      caseProfile = "3ee09b8f-3140-4d08-a034-e222f6d92632";
    in
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

      # CoolerControl. config.toml and overrides.toml are writable copies, replaced on every
      # activation: UI tweaks last until the next switch/boot. Port them here from
      # `diff -u /etc/static/coolercontrol/config.toml /etc/coolercontrol/config.toml` (same for overrides.toml,
      # calibrations.json).
      # Rest of /etc/coolercontrol (password, cert) persists, see preservation.nix.
      programs.coolercontrol.enable = true;
      environment.etc."coolercontrol/config.toml" = {
        mode = "0644";
        source = toml.generate "coolercontrol.toml" {
          devices = { }; # daemon fills it
          legacy690 = { };
          device-settings = {
            ${nct6799} = {
              fan1.profile_uid = caseProfile; # top fans
              fan2.profile_uid = cpuProfile; # cpu/rear fans
            };
            ${rtx5080} = {
              fan1.profile_uid = gpuProfile;
              fan2.profile_uid = gpuProfile;
            };
          };
          # speed_profile points are [temp °C (float), duty %]
          profiles = [
            {
              uid = "0";
              name = "Unmanaged";
              p_type = "Default";
              function = "0";
            }
            {
              uid = gpuProfile;
              name = "GPU";
              p_type = "Graph";
              function_uid = "0";
              speed_profile = [
                [ 0.0 10 ]
                [ 55.0 10 ]
                [ 65.0 40 ]
                [ 75.0 80 ]
                [ 85.0 90 ]
                [ 100.0 100 ]
              ];
              temp_source = {
                temp_name = "GPU Temp";
                device_uid = rtx5080;
              };
              temp_min = 0.0;
              temp_max = 100.0;
            }
            {
              uid = cpuProfile;
              name = "CPU";
              p_type = "Graph";
              function_uid = "0";
              speed_profile = [
                [ 0.0 30 ]
                [ 55.0 30 ]
                [ 75.0 80 ]
                [ 90.0 90 ]
                [ 100.0 100 ]
              ];
              temp_source = {
                temp_name = "temp3";
                device_uid = cpu;
              };
              temp_min = 0.0;
              temp_max = 100.0;
            }
            {
              uid = caseProfile;
              name = "Case";
              p_type = "Mix";
              function_uid = "0";
              member_profile_uids = [
                gpuProfile
                cpuProfile
              ];
              mix_function_type = "Max";
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
            ${nct6799} = {
              name = "nct6799";
              disable = false;
              channel_settings = {
                fan6.disabled = true;
                fan7.disabled = true;
                temp3 = { label = "Auxtin0"; disabled = true; };
                temp4 = { label = "Auxtin1"; disabled = true; };
                temp5 = { label = "Auxtin2"; disabled = true; };
                temp7 = { label = "Auxtin4"; disabled = true; };
                temp10 = { label = "Auxtin5"; disabled = true; };
                temp11 = { label = "Pch Chip Cpu Max Temp"; disabled = true; };
                temp12 = { label = "Pch Chip Temp"; disabled = true; };
              };
            };
          };
        };
      };
      # Measured duty→rpm curves, from the UI's fan calibration. Rerun it after swapping fans.
      environment.etc."coolercontrol/calibrations.json" = {
        mode = "0644";
        source = ./fans-calibrations.json;
      };
      environment.etc."coolercontrol/overrides.toml" = {
        mode = "0644";
        source = toml.generate "coolercontrol-overrides.toml" {
          devices.${nct6799} = {
            device_name = "nct6799";
            channels = {
              fan1.label = "top fans";
              fan2.label = "cpu/rear fans";
            };
          };
        };
      };
    };

  # CoolerControl desktop app. It rewrites CoolerControl.conf with its daemon token and session
  # cookie, so the file stays plain and is only seeded when missing (every boot, /home is tmpfs).
  den.aspects.fans.provides.to-users.homeManager =
    { config, lib, pkgs, ... }:
    let
      seed = pkgs.writeText "CoolerControl.conf" ''
        [General]
        closePromptShown=true
        closeToTray=false
      '';
    in
    {
      home.activation.coolercontrolUi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        conf=${lib.escapeShellArg "${config.xdg.configHome}/org.coolercontrol.CoolerControl/CoolerControl.conf"}
        [ -e "$conf" ] || run install -Dm600 ${seed} "$conf"
      '';
    };
}
