#!/usr/bin/env bash
set -Eeuo pipefail
ISO="${1:?Usage: qemu-uefi-smoke.sh path/to/BanaOS.iso}"
command -v qemu-system-x86_64 >/dev/null
command -v timeout >/dev/null
# Use a matching writable OVMF variable store with its firmware code image.
OVMF_CODE="$(find -L /usr/share/OVMF -maxdepth 1 -type f -name 'OVMF_CODE_4M.fd' -print -quit 2>/dev/null || true)"
OVMF_VARS="$(find -L /usr/share/OVMF -maxdepth 1 -type f -name 'OVMF_VARS_4M.fd' -print -quit 2>/dev/null || true)"
if [[ -z "$OVMF_CODE" || -z "$OVMF_VARS" ]]; then
  OVMF_CODE="$(find -L /usr/share/OVMF -maxdepth 1 -type f -name 'OVMF_CODE.fd' -print -quit 2>/dev/null || true)"
  OVMF_VARS="$(find -L /usr/share/OVMF -maxdepth 1 -type f -name 'OVMF_VARS.fd' -print -quit 2>/dev/null || true)"
fi
[[ -n "$OVMF_CODE" && -s "$OVMF_CODE" && -n "$OVMF_VARS" && -s "$OVMF_VARS" ]] || {
  echo "Matching OVMF_CODE and OVMF_VARS firmware files were not found" >&2
  find -L /usr/share/OVMF -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || true
  exit 2
}
TMP="$(mktemp -d)"
LOG="$TMP/serial.log"
VARS_COPY="$TMP/OVMF_VARS.fd"
cp "$OVMF_VARS" "$VARS_COPY"
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT
set +e
timeout --signal=TERM 55s qemu-system-x86_64 \
  -machine q35,accel=tcg -cpu max -m 1024 \
  -drive if=pflash,format=raw,unit=0,file="$OVMF_CODE",readonly=on \
  -drive if=pflash,format=raw,unit=1,file="$VARS_COPY" \
  -cdrom "$ISO" -boot order=d \
  -display none -serial "file:$LOG" -monitor none \
  -no-reboot -no-shutdown
rc=$?
set -e
# 124 is expected: QEMU remains running after the live system boots.
if [[ "$rc" -ne 124 && "$rc" -ne 0 ]]; then
  cat "$LOG" >&2
  echo "QEMU exited unexpectedly with status $rc" >&2
  exit 1
fi
if ! grep -Eq 'Linux version|Run /sbin/init as init process|Starting init:' "$LOG"; then
  cat "$LOG" >&2
  echo "UEFI firmware did not reach the BanaOS Linux kernel/init sequence" >&2
  exit 1
fi
echo "UEFI QEMU smoke test passed."
