# Desktop: Ryzen 7 9800X3D, RTX 5080, ASUS ROG STRIX B850-I, 2TB SN850X + 2TB SN770 NVMe.
# The display uses the iGPU and the 5080 renders games through PRIME offload.
{ den, ... }:
{
  den.hosts.x86_64-linux.winterfell = {
    disks.main = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_2000GB_22302C801545";
    disks.data = "/dev/disk/by-id/nvme-WD_BLACK_SN770_2TB_244647801062";
    users.mario = { };
  };

  den.aspects.winterfell = {
    includes = [
      den.aspects.disks
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.fans
      den.aspects.peripherals
      den.aspects.workstation
      den.aspects.mario-keys
      den.aspects.rex
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        boot.initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "xhci_pci_prom21" # chipset USB (ensures a keyboard at the LUKS prompt)
          "ahci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];

        boot.kernelPackages = pkgs.linuxPackages_zen;
        services.scx-loader = {
          enable = true;
          config.default_sched = "scx_lavd";
        };
        boot.kernelModules = [
          "kvm-amd"
          "nct6775" # NCT6799D: 4 fan headers, 4 PWM
          "asus_ec_sensors" # VRM, chipset, water temps
        ];
        # PPD's state file is on the tmpfs root so set it as `performance` manually
        systemd.services.ppd-performance = {
          # PPD orders itself after multi-user.target
          wantedBy = [ "power-profiles-daemon.service" ];
          after = [ "power-profiles-daemon.service" ];
          bindsTo = [ "power-profiles-daemon.service" ];
          serviceConfig.Type = "oneshot";
          script = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
        };
        # Disable 5080 FE RGB
        systemd.services.gpu-rgb-off =
          let
            sleep = [
              "suspend.target"
              "hibernate.target"
              "hybrid-sleep.target"
              "suspend-then-hibernate.target"
            ];
          in
          {
            wantedBy = [ "multi-user.target" ] ++ sleep;
            after = [ "systemd-modules-load.service" ] ++ sleep;
            # No HID/USB/i2c access
            serviceConfig = {
              Type = "oneshot";
              DynamicUser = true;
              RuntimeDirectory = "gpu-rgb-off";
            };
            environment.HOME = "/run/gpu-rgb-off"; # OpenRGB writes its config here
            script = ''${lib.getExe pkgs.openrgb} --noautoconnect -d "RTX 5080" -m off'';
          };
        environment.systemPackages = [
          pkgs.discord
          pkgs.wakeonlan
        ];
        boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; # builds highgarden (Pi 5)
        services.smartd.enable = true;
        hardware.enableRedistributableFirmware = true;
        hardware.cpu.amd.updateMicrocode = true;

        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.graphics.enable32Bit = true;
        hardware.nvidia = {
          open = true;
          modesetting.enable = true;
          powerManagement.enable = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          # `nvidia-offload %command%` in Steam launch options
          prime = {
            offload.enable = true;
            offload.enableOffloadCmd = true;
            amdgpuBusId = "PCI:13:0:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        };
      };
  };
}
