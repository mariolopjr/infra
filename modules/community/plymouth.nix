{
  infra.plymouth.nixos = {
    boot = {
      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "systemd.show_status=auto"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "loglevel=0"
      ];

      plymouth.enable = true;
    };
  };
}
