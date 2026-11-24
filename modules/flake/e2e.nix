# End-to-end: boot this machine's arch installer in qemu (macOS HVF, Linux KVM) with two
# blank disks, run `infra-install winterfell-vm`, and reboot.
#   nix run .#e2e          boot installer ISO
#   nix run .#e2e -- boot  boot installed disks
#   nix run .#e2e -- reset delete disks and EFI vars
# State lives in $E2E_DIR (default /cache/e2e if it exists, else ./.e2e).
{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs
      (lib.elem system [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ])
      {
        packages.e2e =
          let
            iso =
              inputs.self.nixosConfigurations."installer-vm-${lib.head (lib.splitString "-" system)}".config;
          in
          pkgs.writeShellApplication {
            name = "e2e";
            runtimeInputs = [ pkgs.qemu ];
            runtimeEnv = {
              QEMU_FW = "${pkgs.qemu}/share/qemu";
              INSTALLER_ISO = "${iso.system.build.isoImage}/${iso.image.filePath}";
            };
            text = builtins.readFile ./e2e.sh;
          };
      };
}
