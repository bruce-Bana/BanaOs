#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/config/release.env"
[[ "$DISTRO_NAME" == "BanaOS" ]]
[[ "$TC_ARCH" == "x86_64" ]]
[[ "$TC_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]
[[ "$TC_ISO_NAME" == CorePure64-* ]]
[[ "$TC_MIRROR_ROOTS" == https://* ]]
for f in config/desktop/jwmrc config/desktop/xsession config/desktop/banaos-menu config/desktop/.profile config/boot/grub.cfg tests/qemu-uefi-smoke.sh build/build-iso.sh; do [[ -s "$ROOT/$f" ]]; done
while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="$(printf '%s' "${line%%#*}" | xargs)"
  [[ -z "$pkg" ]] && continue
  [[ "$pkg" == *.tcz ]] || { echo "Invalid extension: $pkg" >&2; exit 1; }
done < "$ROOT/config/packages.list"
grep -q 'Xorg-jwm-desktop.tcz' "$ROOT/config/packages.list"
grep -q 'onboot.lst' "$ROOT/build/build-iso.sh"
grep -q 'boot_image any replay' "$ROOT/build/build-iso.sh"
grep -q 'efi_path=/boot/efiboot.img' "$ROOT/build/build-iso.sh"
grep -q 'efi_boot_part=--efi-boot-image' "$ROOT/build/build-iso.sh"
grep -q 'boot_image any next' "$ROOT/build/build-iso.sh"
grep -q 'platform_id=0xef' "$ROOT/build/build-iso.sh"
grep -q 'grub-mkstandalone' "$ROOT/build/build-iso.sh"
echo "BanaOS configuration checks passed."
