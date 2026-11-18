#!/usr/bin/env bash
# e2e [install|boot|reset]. e2e.nix sets QEMU_FW (qemu's share/qemu) and INSTALLER_ISO.
set -euo pipefail

default=$PWD/.e2e
[[ -d /cache/e2e ]] && default=/cache/e2e # NixOS hosts: off the snapshotted /persist (preservation.nix)
dir=${E2E_DIR:-$default}
mode=${1:-install}

if [[ $mode == reset ]]; then
  rm -rf "$dir"
  exit
fi
case $(uname -sm) in
"Darwin arm64")
  vm=(qemu-system-aarch64 -machine "virt,accel=hvf") code=aarch64 vars=arm
  gpu=(-device "virtio-gpu-pci,xres=2880,yres=1800" -display cocoa)
  ;;
"Linux aarch64")
  vm=(qemu-system-aarch64 -machine "virt,accel=kvm") code=aarch64 vars=arm
  gpu=(-device "virtio-gpu-gl-pci,xres=2880,yres=1800" -display "gtk,gl=on")
  ;;
"Linux x86_64")
  vm=(qemu-system-x86_64 -machine "q35,accel=kvm") code=x86_64 vars=i386
  gpu=(-vga none -device "virtio-vga-gl,xres=2880,yres=1800" -display "gtk,gl=on")
  ;;
*)
  echo "e2e: unsupported host $(uname -sm)" >&2
  exit 1
  ;;
esac

mkdir -p "$dir"
[[ -f $dir/main.qcow2 ]] || qemu-img create -q -f qcow2 "$dir/main.qcow2" 64G
[[ -f $dir/data.qcow2 ]] || qemu-img create -q -f qcow2 "$dir/data.qcow2" 32G
[[ -f $dir/vars.fd ]] || {
  cp "$QEMU_FW/edk2-$vars-vars.fd" "$dir/vars.fd"
  chmod u+w "$dir/vars.fd"
}

cdrom=()
if [[ $mode == install ]]; then
  cdrom=(-drive "if=none,id=cd,media=cdrom,readonly=on,file=$INSTALLER_ISO" -device "usb-storage,drive=cd,bootindex=0")
fi

exec "${vm[@]}" -cpu host -smp 6 -m 12G \
  -drive "if=pflash,format=raw,readonly=on,file=$QEMU_FW/edk2-$code-code.fd" \
  -drive "if=pflash,format=raw,file=$dir/vars.fd" \
  -drive "if=none,id=main,format=qcow2,file=$dir/main.qcow2" -device "virtio-blk-pci,drive=main,serial=main,bootindex=1" \
  -drive "if=none,id=data,format=qcow2,file=$dir/data.qcow2" -device "virtio-blk-pci,drive=data,serial=data" \
  -device qemu-xhci -device usb-kbd -device usb-tablet \
  "${gpu[@]}" \
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 \
  "${cdrom[@]}"
