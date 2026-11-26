#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/release.env"
WORK="${WORK_DIR:-$ROOT/work}"
DIST="${DIST_DIR:-$ROOT/dist}"
CACHE="${CACHE_DIR:-$ROOT/.cache}"
BASE_ISO="${BASE_ISO:-}"
SKIP_MD5="${SKIP_MD5:-0}"
MIRRORS="${TC_MIRROR_ROOTS:-$TC_MIRROR_ROOTS}"
mkdir -p "$WORK" "$DIST" "$CACHE"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 2; }; }
for c in curl md5sum sha256sum awk sed tar xorriso sort grep grub-mkstandalone mkfs.vfat mmd mcopy dd; do need "$c"; done

LAST_MIRROR=""
download_required() {
  local relative="$1" destination="$2" root tmp
  tmp="$destination.part"
  rm -f "$tmp"
  for root in $MIRRORS; do
    echo "Fetching $relative from $root"
    if curl --fail --location --silent --show-error --connect-timeout 20 --max-time 600 --retry 2 --retry-delay 2 "$root/$relative" -o "$tmp"; then
      mv "$tmp" "$destination"
      LAST_MIRROR="$root"
      return 0
    fi
    rm -f "$tmp"
  done
  echo "Unable to fetch required file: $relative" >&2
  return 1
}
download_optional() {
  local relative="$1" destination="$2" root tmp
  tmp="$destination.part"
  rm -f "$tmp"
  # Metadata is tiny and often absent for leaf extensions. Try the mirror
  # that served the package first, then other mirrors with short timeouts.
  local roots=("$LAST_MIRROR")
  for root in $MIRRORS; do
    [[ "$root" == "$LAST_MIRROR" ]] || roots+=("$root")
  done
  for root in "${roots[@]}"; do
    [[ -n "$root" ]] || continue
    if curl --fail --location --silent --connect-timeout 5 --max-time 12 "$root/$relative" -o "$tmp" 2>/dev/null; then
      mv "$tmp" "$destination"
      LAST_MIRROR="$root"
      return 0
    fi
    rm -f "$tmp"
  done
  return 1
}

# Download the official CorePure64 base image and verify its published checksum.
ISO_MIRROR=""
if [[ -z "$BASE_ISO" ]]; then
  BASE_ISO="$CACHE/$TC_ISO_NAME"
  if [[ ! -s "$BASE_ISO" ]]; then
    download_required "$TC_RELEASE_PATH/$TC_ISO_NAME" "$BASE_ISO"
    ISO_MIRROR="$LAST_MIRROR"
  fi
fi
[[ -s "$BASE_ISO" ]] || { echo "Base ISO missing: $BASE_ISO" >&2; exit 1; }
verify_status="not-requested"
if [[ "$SKIP_MD5" != 1 ]]; then
  md5file="$CACHE/$TC_ISO_NAME.md5.txt"
  if [[ -n "$ISO_MIRROR" ]]; then
    curl --fail --location --silent --show-error "$ISO_MIRROR/$TC_RELEASE_PATH/$TC_ISO_NAME.md5.txt" -o "$md5file"
  else
    download_required "$TC_RELEASE_PATH/$TC_ISO_NAME.md5.txt" "$md5file"
  fi
  expected="$(awk 'NR==1{print tolower($1)}' "$md5file")"
  actual="$(md5sum "$BASE_ISO" | awk '{print $1}')"
  [[ "$expected" == "$actual" ]] || { echo "Base ISO checksum mismatch" >&2; exit 1; }
  verify_status="upstream-md5-verified"
else
  verify_status="explicitly-skipped"
fi

# Resolve the full extension dependency closure. Only requested roots are put
# in onboot.lst; Tiny Core automatically pulls their dependencies from .dep.
EXT="$WORK/extensions"
rm -rf "$EXT" "$WORK/iso-root" "$WORK/home"
mkdir -p "$EXT" "$WORK/iso-root" "$WORK/home/tc/Desktop" "$WORK/home/tc/.config"
declare -A seen=()
queue=()
while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="$(printf '%s' "${line%%#*}" | xargs)"
  [[ -z "$pkg" ]] && continue
  [[ "$pkg" == *.tcz ]] || { echo "Invalid extension: $pkg" >&2; exit 1; }
  queue+=("$pkg")
done < "$ROOT/config/packages.list"
while (("${#queue[@]}")); do
  pkg="${queue[0]}"
  queue=("${queue[@]:1}")
  [[ -n "${seen[$pkg]:-}" ]] && continue
  seen[$pkg]=1
  download_required "$TC_EXTENSION_PATH/$pkg" "$EXT/$pkg"
  if download_optional "$TC_EXTENSION_PATH/$pkg.dep" "$EXT/$pkg.dep"; then
    while IFS= read -r dep || [[ -n "$dep" ]]; do
      dep="$(printf '%s' "${dep%%#*}" | xargs)"
      [[ -z "$dep" ]] && continue
      [[ "$dep" == *.tcz ]] || { echo "Invalid dependency '$dep' in $pkg.dep" >&2; exit 1; }
      [[ -n "${seen[$dep]:-}" ]] || queue+=("$dep")
    done < "$EXT/$pkg.dep"
  fi
  if download_optional "$TC_EXTENSION_PATH/$pkg.md5.txt" "$EXT/$pkg.md5.txt"; then
    expected="$(awk 'NR==1{print tolower($1)}' "$EXT/$pkg.md5.txt")"
    actual="$(md5sum "$EXT/$pkg" | awk '{print $1}')"
    [[ "$expected" == "$actual" ]] || { echo "Extension checksum mismatch: $pkg" >&2; exit 1; }
  else
    echo "Warning: no MD5 metadata for $pkg; downloaded via HTTPS." >&2
  fi
done

# Extract the ISO and update files while preserving its original boot structures.
xorriso -osirrox on -indev "$BASE_ISO" -extract / "$WORK/iso-root" >/dev/null
# ISO directory entries are read-only. Make the tree editable for remastering.
chmod -R u+w "$WORK/iso-root"
# Build a FAT EFI System Partition with a self-contained GRUB x86_64 loader.
EFI_IMG="$WORK/efiboot.img"
EFI_BIN="$WORK/BOOTX64.EFI"
grub-mkstandalone --format=x86_64-efi --output="$EFI_BIN" \
  --locales="" --fonts="" \
  --modules="part_gpt part_msdos iso9660 fat normal linux search search_fs_file serial all_video efi_gop efi_uga" \
  "boot/grub/grub.cfg=$ROOT/config/boot/grub.cfg"
dd if=/dev/zero of="$EFI_IMG" bs=1M count=16 status=none
mkfs.vfat -F 16 "$EFI_IMG" >/dev/null
mmd -i "$EFI_IMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFI_IMG" "$EFI_BIN" ::/EFI/BOOT/BOOTX64.EFI
cp "$EFI_IMG" "$WORK/iso-root/boot/efiboot.img"
# ISO directory entries are normally read-only; make the extracted tree editable.
chmod -R u+w "$WORK/iso-root"
if [[ ! -f "$WORK/iso-root/boot/isolinux/isolinux.cfg" ]]; then
  echo "Expected Tiny Core ISOLINUX configuration not found in base ISO." >&2
  exit 1
fi
if ! grep -Eq '^[[:space:]]*APPEND .*([[:space:]]|^)cde([[:space:]]|$)' "$WORK/iso-root/boot/isolinux/isolinux.cfg"; then
  sed -i '/^[[:space:]]*APPEND /s/$/ cde/' "$WORK/iso-root/boot/isolinux/isolinux.cfg"
fi
mkdir -p "$WORK/iso-root/cde/optional"
cp "$EXT/"*.tcz "$WORK/iso-root/cde/optional/"
cp "$EXT/"*.dep "$WORK/iso-root/cde/optional/" 2>/dev/null || true
cp "$EXT/"*.md5.txt "$WORK/iso-root/cde/optional/" 2>/dev/null || true
: > "$WORK/iso-root/cde/onboot.lst"
while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="$(printf '%s' "${line%%#*}" | xargs)"
  [[ -n "$pkg" ]] && printf '%s\n' "$pkg" >> "$WORK/iso-root/cde/onboot.lst"
done < "$ROOT/config/packages.list"
cp "$ROOT/config/packages.list" "$WORK/iso-root/cde/banaos-packages.list"

# Restore desktop files and auto-start X on the local GUI console.
cp "$ROOT/config/desktop/jwmrc" "$WORK/home/tc/.jwmrc"
cp "$ROOT/config/desktop/wallpaper.svg" "$WORK/home/tc/.wallpaper.svg"
cp "$ROOT/config/desktop/banaos-menu" "$WORK/home/tc/banaos-menu"
cp "$ROOT/config/desktop/xsession" "$WORK/home/tc/.xsession"
cp "$ROOT/config/desktop/.profile" "$WORK/home/tc/.profile"
chmod +x "$WORK/home/tc/.xsession" "$WORK/home/tc/banaos-menu"
cp "$ROOT/config/desktop/README.txt" "$WORK/home/tc/Desktop/Welcome to BanaOS.txt"
cp "$ROOT/config/desktop/pcmanfm.conf" "$WORK/home/tc/.config/pcmanfm.conf"
tar -czf "$WORK/iso-root/cde/mydata.tgz" -C "$WORK/home" tc

cat > "$WORK/iso-root/BANAOS-INFO.txt" <<INFO
$DISTRO_NAME $DISTRO_VERSION
Architecture: $TC_ARCH
Base: Tiny Core CorePure64 $TC_VERSION
Desktop: Xorg/JWM, PCManFM, LXTerminal
Boot modes: BIOS + UEFI (GRUB EFI)
Image type: experimental live ISO; no installer included
Base ISO verification: $verify_status
Resolved extensions: ${#seen[@]}
INFO

out="$DIST/$DISTRO_NAME-$DISTRO_VERSION-x86_64.iso"
rm -f "$out"
# Restore read-only media permissions before importing the tree.
chmod -R a-w "$WORK/iso-root"
xorriso -indev "$BASE_ISO" -outdev "$out" \
  -update_r "$WORK/iso-root" / \
  -boot_image any replay \
  -boot_image any efi_path=/boot/efiboot.img \
  -efi_boot_part --efi-boot-image -commit
xorriso -indev "$out" -report_el_torito plain > "$DIST/boot-report.txt" 2>&1
grep -qi 'El Torito' "$DIST/boot-report.txt" || { echo "Boot catalog missing from remastered ISO" >&2; exit 1; }
grep -qi 'BIOS' "$DIST/boot-report.txt" || { echo "BIOS boot entry missing" >&2; exit 1; }
grep -qi 'EFI' "$DIST/boot-report.txt" || { echo "UEFI boot entry missing" >&2; exit 1; }
(cd "$DIST" && sha256sum "$(basename "$out")" > "$(basename "$out").sha256")
{
  echo "Distribution=$DISTRO_NAME"
  echo "Version=$DISTRO_VERSION"
  echo "Architecture=$TC_ARCH"
  echo "TinyCoreBase=$TC_VERSION"
  echo "ResolvedExtensions=${#seen[@]}"
  echo "BootModes=BIOS,UEFI"
  echo "UpstreamVerification=$verify_status"
  echo "MirrorRoots=$MIRRORS"
  echo "Output=$(basename "$out")"
} > "$DIST/build-manifest.txt"
echo "Built: $out"
echo "SHA256: $(awk '{print $1}' "$out.sha256")"
