{
  inputs,
  lib,
  den,
  ...
}:
let
  # e2e VM, one per arch: `just vm` boots the one matching the machine it runs on.
  vm = {
    hostName = "winterfell-vm";
    aspect = den.aspects.winterfell-vm;
    disks.main = "/dev/disk/by-id/virtio-main";
    disks.data = "/dev/disk/by-id/virtio-data";
    users.mario = { };
  };
in
{
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.winterfell = {
    disks.main = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_2000GB_22302C801545";
    disks.data = "/dev/disk/by-id/nvme-WD_BLACK_SN770_2TB_244647801062";
    users.mario = { };
  };

  den.hosts.x86_64-linux.winterfell-vm-x86_64 = vm;
  den.hosts.aarch64-linux.winterfell-vm-aarch64 = vm;

  den.hosts.aarch64-darwin.dragonstone.users.mario = { };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
  den.schema.host.includes = [
    den.batteries.hostname
    den.batteries.mutual-provider
  ];

  den.default.nixos.system.stateVersion = "26.11";
  den.default.darwin.system.stateVersion = 6;
  den.default.homeManager.home.stateVersion = "26.11";
  den.default.os.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true; # /etc/profiles/per-user/<user>
    backupFileExtension = "pre-hm";
  };
}
