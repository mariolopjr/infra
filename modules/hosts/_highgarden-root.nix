# sdImage.rootFilesystemCreator: nixpkgs' make-btrfs-fs.nix, but with highgarden's subvolumes.
# The store and its registration go in @nix; @root starts empty and is recreated every boot.
{
  pkgs,
  lib,
  storePaths,
  compressImage ? false,
  volumeLabel,
  populateImageCommands ? "", # unused: the Pi's boot files live on the firmware partition
  uuid ? "44444444-4444-4444-8888-888888888888",
  btrfs-progs,
  fakeroot,
  libfaketime,
  zstd,
}:
let
  closure = pkgs.buildPackages.closureInfo { rootPaths = storePaths; };
  subvols = [
    "@root"
    "@nix"
    "@log"
    "@persist"
    "@persist/.snapshots" # snapper's
  ];
in
pkgs.stdenv.mkDerivation {
  name = "btrfs-fs.img${lib.optionalString compressImage ".zst"}";
  nativeBuildInputs = [
    btrfs-progs
    fakeroot
    libfaketime
  ]
  ++ lib.optional compressImage zstd;

  buildCommand = ''
    img=${if compressImage then "temp.img" else "$out"}
    mkdir -p ${lib.concatMapStringsSep " " (s: "rootImage/${s}") subvols} rootImage/@nix/store
    xargs -I % cp -a --reflink=auto % -t rootImage/@nix/store/ < ${closure}/store-paths
    cp ${closure}/registration rootImage/@nix/nix-path-registration

    touch $img
    faketime -f "1970-01-01 00:00:01" fakeroot mkfs.btrfs -L ${volumeLabel} -U ${uuid} \
      -r rootImage ${lib.concatMapStringsSep " " (s: "--subvol ${s}") subvols} \
      --compress zstd:1 --shrink $img
    btrfs check $img
    ${lib.optionalString compressImage "zstd -v --no-progress $img -o $out"}
  '';
}
