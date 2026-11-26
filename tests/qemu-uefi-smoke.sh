#!/usr/bin/env bash
set -Eeuo pipefail
ISO="${1:?Usage: qemu-uefi-smoke.sh path/to/BanaOS.iso}"
command -v qemu-system-x86_64 >/dev/null
command -v timeout >/dev/null
OVMF_CODE="$(find /usr/share/OVMF /usr/share/qemu -name 'OVMF_CODE*.fd' -print -quit 2>/dev/null || true)"
[[ -n "$OVMF_CODE" && -s "$OVMF_CODE" ]] || { echo "OVMF firmware not found" >&2; exit 2; }
LOG="$(mktemp)"
cleanup(){ rm -f "$LOG"; }
trap cleanup EXIT
set +e
timeout --signal=TERM 55s qemu-system-x86_64 \
  -machine q35,accel=tcg -cpu max -m 1024 \
  -bios "$OVMF_CODE" -cdrom "$ISO" -boot d \
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
