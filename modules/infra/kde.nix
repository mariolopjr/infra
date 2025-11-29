{
  infra.kde = _: {
    nixos = {
      services.desktopManager.plasma6.enable = true;
    };
  };
}
