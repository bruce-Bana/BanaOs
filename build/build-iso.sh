#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/config/release.env"
WORK="${WORK_DIR:-$ROOT/work}"
DIST="${DIST_DIR:-$ROOT/dist}"
CACHE="${CACHE_DIR:-$ROOT/.cache}"
BASE_ISO="${BASE_ISO:-}"
TC_REPO="${TC_REPO:-$TC_REPO}"
SKIP_MD5="${SKIP_MD5:-0}"
mkdir -p "$WORK" "$DIST" "$CACHE"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 2; }; }
for c in curl md5sum sha256sum awk sed tar xorriso sort; do need "$c"; done

if [[ -z "$BASE_ISO" ]]; then
  BASE_ISO="$CACHE/$TC_ISO_NAME"
  [[ -s "$BASE_ISO" ]] || curl --fail --location --retry 3 "$TC_RELEASE_URL/$TC_ISO_NAME" -o "$BASE_ISO"
fi
[[ -s "$BASE_ISO" ]] || { echo "Base ISO missing: $BASE_ISO" >&2; exit 1; }

verify_status="not-requested"
if [[ "$SKIP_MD5" != 1 ]]; then
  md5file="$CACHE/$TC_ISO_NAME.md5.txt"
  if curl --fail --location --silent --show-error "$TC_RELEASE_URL/$TC_ISO_NAME.md5.txt" -o "$md5file"; then
    expected="$(awk 'NR==1{print tolower($1)}' "$md5file")"
    actual="$(md5sum "$BASE_ISO" | awk '{print $1}')"
    [[ "$expected" == "$actual" ]] || { echo "Base ISO checksum mismatch" >&2; exit 1; }
    verify_status="upstream-md5-verified"
  else
    echo "Upstream MD5 metadata unavailable. Set SKIP_MD5=1 only after independent verification." >&2
    exit 1
  fi
else
  verify_status="explicitly-skipped"
fi

# Resolve the requested extension dependency closure from Tiny Core's official mirror.
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
  echo "Downloading $pkg"
  curl --fail --location --retry 3 "$TC_REPO/$pkg" -o "$EXT/$pkg"
  if curl --fail --location --silent "$TC_REPO/$pkg.dep" -o "$EXT/$pkg.dep"; then
    while IFS= read -r dep || [[ -n "$dep" ]]; do
      dep="$(printf '%s' "${dep%%#*}" | xargs)"
      [[ -z "$dep" ]] && continue
      [[ "$dep" == *.tcz ]] || { echo "Invalid dependency '$dep' in $pkg.dep" >&2; exit 1; }
      [[ -n "${seen[$dep]:-}" ]] || queue+=("$dep")
    done < "$EXT/$pkg.dep"
  fi
  if curl --fail --location --silent "$TC_REPO/$pkg.md5.txt" -o "$EXT/$pkg.md5.txt"; then
    expected="$(awk 'NR==1{print tolower($1)}' "$EXT/$pkg.md5.txt")"
    actual="$(md5sum "$EXT/$pkg" | awk '{print $1}')"
    [[ "$expected" == "$actual" ]] || { echo "Extension checksum mismatch: $pkg" >&2; exit 1; }
  fi
done

# Extract the original ISO tree while retaining its bootloader assets.
xorriso -osirrox on -indev "$BASE_ISO" -extract / "$WORK/iso-root" >/dev/null

# Tell Tiny Core to load extensions and restore mydata.tgz from the CD's cde directory.
if [[ -f "$WORK/iso-root/boot/isolinux/isolinux.cfg" ]]; then
  if grep -qE '^[[:space:]]*APPEND .*\\bcde\\b' "$WORK/iso-root/boot/isolinux/isolinux.cfg"; then
    :
  else
    sed -i '/^[[:space:]]*APPEND /s/$/ cde/' "$WORK/iso-root/boot/isolinux/isolinux.cfg"
  fi
fi
mkdir -p "$WORK/iso-root/cde/optional"
cp "$EXT/"*.tcz "$WORK/iso-root/cde/optional/"
cp "$EXT/"*.dep "$WORK/iso-root/cde/optional/" 2>/dev/null || true
cp "$EXT/"*.md5.txt "$WORK/iso-root/cde/optional/" 2>/dev/null || true
: > "$WORK/iso-root/cde/onboot.lst"
for pkg in "${!seen[@]}"; do printf '%s\n' "$pkg" >> "$WORK/iso-root/cde/onboot.lst"; done
sort -o "$WORK/iso-root/cde/onboot.lst" "$WORK/iso-root/cde/onboot.lst"
cp "$ROOT/config/packages.list" "$WORK/iso-root/cde/banaos-packages.list"

# Tiny Core restores this user backup at boot; keep ownership/modes consistent.
cp "$ROOT/config/desktop/jwmrc" "$WORK/home/tc/.jwmrc"
cp "$ROOT/config/desktop/wallpaper.svg" "$WORK/home/tc/.wallpaper.svg"
cp "$ROOT/config/desktop/banaos-menu" "$WORK/home/tc/banaos-menu"
cp "$ROOT/config/desktop/xsession" "$WORK/home/tc/.xsession"
chmod +x "$WORK/home/tc/.xsession" "$WORK/home/tc/banaos-menu"
cp "$ROOT/config/desktop/README.txt" "$WORK/home/tc/Desktop/Welcome to BanaOS.txt"
cp "$ROOT/config/desktop/pcmanfm.conf" "$WORK/home/tc/.config/pcmanfm.conf"
tar -czf "$WORK/iso-root/cde/mydata.tgz" -C "$WORK/home" tc

cat > "$WORK/iso-root/BANAOS-INFO.txt" <<INFO
$DISTRO_NAME $DISTRO_VERSION
Architecture: $TC_ARCH
Base: Tiny Core CorePure64 $TC_VERSION
Desktop: Xorg, JWM, PCManFM, LXTerminal, Wbar
Image: experimental live ISO; no installer included
Base ISO verification: $verify_status
Resolved extensions: ${#seen[@]}
INFO

out="$DIST/$DISTRO_NAME-$DISTRO_VERSION-x86_64.iso"
rm -f "$out"
# Replay the original boot catalog (BIOS/UEFI entries) instead of creating a
# generic data ISO that would not be bootable.
xorriso -indev "$BASE_ISO" -outdev "$out" -boot_image any replay \
  -update_r "$WORK/iso-root" / -commit
sha256sum "$out" > "$out.sha256"
{
  echo "Distribution=$DISTRO_NAME"
  echo "Version=$DISTRO_VERSION"
  echo "Architecture=$TC_ARCH"
  echo "TinyCoreBase=$TC_VERSION"
  echo "ResolvedExtensions=${#seen[@]}"
  echo "UpstreamVerification=$verify_status"
  echo "Output=$(basename "$out")"
} > "$DIST/build-manifest.txt"
echo "Built: $out"
echo "SHA256: $(awk '{print $1}' "$out.sha256")"
