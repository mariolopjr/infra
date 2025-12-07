{
  infra.lact = _: {
    nixos = {
      services.lact = {
        enable = true;
      };
    };
  };
}
