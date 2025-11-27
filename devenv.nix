{
  pkgs,
  ...
}:
{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  packages = [
    pkgs.age
    pkgs.alejandra
    pkgs.just
    pkgs.nixd
    pkgs.nh
    pkgs.sops
    pkgs.ssh-to-age
  ];

  # https://devenv.sh/basics/
  # enterShell = ''
  #   exec fish
  # '';
}
