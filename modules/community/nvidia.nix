{
  infra.nvidia.nixos = {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = true;
    };
  };
}
