# GPU (LACT) and case fan (CoolerControl) control
{
  den.aspects.fans.nixos =
    { pkgs, ... }:
    let
      toml = pkgs.formats.toml { };
      # coolercontrold's device hash, also in fans-config.toml
      nct6799 = "00a4da18625f56275c89e2fcd25a83c08c5ad3326452fa7e252fcc8a89c92493";
    in
    {
      # LACT: RTX 5080 overclock/power only, CoolerControl owns the fans. GPUs key on the PCI id
      # from `lact cli list-gpus`. Hand-written, not services.lact.settings: pkgs.formats.yaml quotes
      # the offset keys ('0': 500) and lactd rejects quoted ints. Writable copy replaced on every
      # activation, lactd reloads it on change. Port UI tweaks from
      # `diff -u /etc/static/lact/config.yaml /etc/lact/config.yaml`.
      services.lact.enable = true;
      environment.etc."lact/config.yaml" = {
        mode = "0644";
        text = ''
          version: 7
          daemon:
            log_level: info
            admin_group: wheel
            disable_clocks_cleanup: false
          apply_settings_timer: 5
          gpus:
            10DE:2C02-10DE:2095-0000:01:00.0:
              fan_control_enabled: false
              power_mizer_mode: Adaptive
              power_cap: 380.0
              min_core_clock: 180
              max_core_clock: 3150
              gpu_clock_offsets:
                0: 250
              mem_clock_offsets:
                0: 2000
        '';
      };

      # CoolerControl. config.toml and overrides.toml are writable copies, replaced on every
      # activation: UI tweaks last until the next switch/boot. Port them here from
      # `diff -u /etc/static/coolercontrol/config.toml /etc/coolercontrol/config.toml` (same for overrides.toml,
      # calibrations.json).
      # Rest of /etc/coolercontrol (password, cert) persists, see preservation.nix.
      programs.coolercontrol.enable = true;
      # Separate file, not pkgs.formats.toml: the daemon requires inline tables, the generator
      # emits [table] headers.
      environment.etc."coolercontrol/config.toml" = {
        mode = "0644";
        source = ./fans-config.toml;
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
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
