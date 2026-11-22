# MacBook Pro M1 Pro
{
  den.aspects.dragonstone.darwin = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PermitRootLogin no
      '';
    };
  };
}
