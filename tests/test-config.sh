#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/config/release.env"
[[ "$DISTRO_NAME" == "BanaOS" ]]
[[ "$TC_ARCH" == "x86_64" ]]
[[ "$TC_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]
[[ "$TC_ISO_NAME" == CorePure64-* ]]
for f in config/desktop/jwmrc config/desktop/xsession config/desktop/banaos-menu build/build-iso.sh; do [[ -s "$ROOT/$f" ]]; done
while IFS= read -r line || [[ -n "$line" ]]; do
  pkg="$(printf '%s' "${line%%#*}" | xargs)"
  [[ -z "$pkg" ]] && continue
  [[ "$pkg" == *.tcz ]] || { echo "Invalid extension: $pkg" >&2; exit 1; }
done < "$ROOT/config/packages.list"
echo "BanaOS configuration checks passed."
