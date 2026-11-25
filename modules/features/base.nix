{
  den.default.nixos =
    { pkgs, ... }:
    {
      boot.loader.limine = {
        enable = true;
        efiSupport = true;
        maxGenerations = 20;
        efiInstallAsRemovable = true;
      };
      boot.loader.efi.canTouchEfiVariables = false;

      networking.networkmanager.enable = true;
      networking.networkmanager.wifi.powersave = false;
      boot.extraModprobeConfig = "options iwlmvm power_scheme=1"; # Intel firmware: always active
      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";

      services.openssh = {
        enable = true;
        # NixOS defaults without RSA
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
          {
            path = "/etc/ssh/ssh_host_mldsa44_ed25519_key";
            type = "mldsa44-ed25519";
          }
        ];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          # AEAD only: integrity comes from the cipher, so sshd skips MAC negotiation
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com" # Rex iOS has no chacha20
          ];
          # Rex iOS requires a MAC match even though AEAD ciphers never use one
          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
            "umac-128-etm@openssh.com"
            "hmac-sha2-256"
          ];
        };
      };
      services.fwupd.enable = true;
      environment.systemPackages = with pkgs; [
        git
        lm_sensors
        pciutils
        usbutils
      ];
    };
}
