{
  infra.virtualization =
    { user, ... }:
    {
      nixos =
        { pkgs, lib, ... }:
        {
          programs.virt-manager.enable = true;

          users.groups.libvirtd.members = [ user.userName ];
          users.groups.kvm.members = [ user.userName ];

          virtualisation.libvirtd = {
            enable = true;

            # Enable TPM emulation (for Windows 11)
            qemu = {
              swtpm.enable = true;
              ovmf.packages = [ pkgs.OVMFFull.fd ];
            };
          };
          virtualisation.spiceUSBRedirection.enable = true;

          networking.firewall.trustedInterfaces = [ "virbr0" ];

          systemd.services.libvirt-default-network = {
            description = "Start libvirt default network";
            after = [ "libvirtd.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${lib.getExe pkgs.libvirt} net-start default";
              ExecStop = "${lib.getExe pkgs.libvirt} net-destroy default";
              User = "root";
            };
          };

          environment.systemPackages = with pkgs; [
            virt-manager
          ];
        };
    };
}
