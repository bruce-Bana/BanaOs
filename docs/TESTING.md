# Testing BanaOS

## Static checks
```bash
bash -n build/build-iso.sh
bash -n config/desktop/xsession
bash -n config/desktop/banaos-menu
bash tests/test-config.sh
```

A passing static test does not prove the ISO boots. Required VM matrix:
- QEMU BIOS, 2 vCPU, 2 GiB RAM.
- QEMU UEFI with OVMF, 2 vCPU, 2 GiB RAM.

Verify display, keyboard, mouse, storage, networking, JWM menu/taskbar, file manager, terminal, shutdown/reboot and persistence. Do not install to a disk until a future installer has been tested with explicit safeguards.
