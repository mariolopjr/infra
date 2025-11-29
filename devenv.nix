{
  pkgs,
  ...
}:
{
  packages = [
    pkgs.age
    pkgs.alejandra
    pkgs.just
    pkgs.nixd
    pkgs.nh
    pkgs.sops
    pkgs.ssh-to-age
  ];
}
