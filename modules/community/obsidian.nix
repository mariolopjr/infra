{
  infra.obsidian.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.obsidian
      ];
    };
}
