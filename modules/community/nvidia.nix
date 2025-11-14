{
  infra.nvidia.nixos = {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
    };
  };
}
