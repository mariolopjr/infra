# Desktop: Ryzen 7 9800X3D, RTX 5080, ASUS ROG STRIX B850-I, 2TB SN850X + 2TB SN770 NVMe.
# The display uses the iGPU and the 5080 renders games through PRIME offload.
{ den, ... }:
{
  den.aspects.winterfell = {
    includes = [
      den.aspects.disks
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.fans
      den.aspects.peripherals
    ];

    nixos =
      { config, pkgs, ... }:
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
        environment.systemPackages = [ pkgs.wakeonlan ];
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
