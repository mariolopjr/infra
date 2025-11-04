{
  infra.aarch64-darwin.darwin =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.coreutils
        pkgs.util-linux
      ];
    };
}
