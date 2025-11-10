{
  infra.bootable.nixos =
    { pkgs, ... }:
    {
      boot = {
        initrd.systemd.enable = true;
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;

        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "usb_storage"
          "sd_mod"
          "uhci_hcd"
          "ehci_pci"
        ];

        kernelPackages = pkgs.linuxPackages_latest;
      };

      services.xserver.xkb = {
        layout = "us";
      };

      console = {
        earlySetup = true;
        useXkbConfig = true;
      };
    };
}
