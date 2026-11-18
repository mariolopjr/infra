{
  den.default.nixos =
    { pkgs, ... }:
    {
      boot.loader.limine = {
        enable = true;
        efiSupport = true;
        maxGenerations = 20;
        efiInstallAsRemovable = true;
        # Keys are made on the first install with none in /var/lib/sbctl; they only enroll if the
        # firmware is in Setup Mode then, else `sbctl enroll-keys -m -f`. -m: GPU option ROMs need Microsoft's CA.
        secureBoot = {
          enable = true;
          autoEnrollKeys.enable = true;
        };
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
