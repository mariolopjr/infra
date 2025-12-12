{
  pkgs,
  ...
}:
{
  packages = [
    pkgs.age
    pkgs.just
    pkgs.nixd
    pkgs.nh
    pkgs.sops
    pkgs.ssh-to-age
  ];
}
