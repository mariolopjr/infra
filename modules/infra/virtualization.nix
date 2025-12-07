{
  infra.virtualization =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          programs.virt-manager.enable = true;

          users.groups.libvirtd.members = [ user.userName ];
          users.groups.kvm.members = [ user.userName ];

          virtualisation.libvirtd = {
            enable = true;

            # Enable TPM emulation (for Windows 11)
            qemu = {
              swtpm.enable = true;
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
              ExecStart = "${pkgs.libvirt}/bin/virsh net-start default";
              ExecStop = "${pkgs.libvirt}/bin/virsh net-destroy default";
              User = "root";
            };
          };

          environment.systemPackages = with pkgs; [
            virtiofsd
            virt-manager
          ];
        };
    };
}
