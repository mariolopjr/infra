{
  infra.sudo.nixos = {
    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';
  };
}
