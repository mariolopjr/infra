{
  infra.quiet.nixos = {
    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "systemd.show_status=auto"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "loglevel=0"
      ];
    };
  };
}
