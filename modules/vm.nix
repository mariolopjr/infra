{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text = ''
          ${inputs.self.nixosConfigurations.winterfell-vm.config.system.build.vmWithDisko}/bin/disko-vm "$@"
        '';
      };
    };
}
