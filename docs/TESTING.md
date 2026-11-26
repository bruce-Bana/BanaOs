# BanaOS testing

## Automated CI checks
- Shell syntax and project configuration.
- Base ISO checksum verification.
- Recursive extension download and checksum verification.
- ISO creation and SHA-256 verification.
- El Torito boot catalog presence after remaster.
- ISO and reports uploaded as a workflow artifact.

A successful build and boot catalog check are not the same as a successful guest OS boot.

## Required manual boot matrix
- QEMU BIOS: 2 vCPU, 1–2 GiB RAM.
- QEMU UEFI/OVMF if supported by the original ISO boot layout.
- Physical x86_64 laptop and desktop.

Verify graphical session startup, display resolution, keyboard, mouse, file manager, terminal, Ethernet/Wi-Fi, storage, audio, shutdown/reboot and persistence. Do not install to a disk until a future installer has explicit safeguards and has been tested independently.
