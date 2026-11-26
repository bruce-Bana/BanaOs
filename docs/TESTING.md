# BanaOS testing

## Automated CI checks
- Shell syntax and project configuration.
- Base ISO checksum verification.
- Recursive extension download and checksum verification.
- ISO creation and SHA-256 verification.
- BIOS and UEFI El Torito boot entries after remaster.
- OVMF/QEMU test that reaches the Linux kernel/init sequence.
- ISO and reports uploaded as a workflow artifact.

The CI UEFI test confirms that OVMF launches GRUB and reaches the Linux init sequence. It does not certify all desktop devices or physical hardware.

## Required manual boot matrix
- QEMU BIOS: 2 vCPU, 1–2 GiB RAM.
- QEMU UEFI/OVMF (automated in CI).
- Physical x86_64 laptop and desktop.

Verify graphical session startup, display resolution, keyboard, mouse, file manager, terminal, Ethernet/Wi-Fi, storage, audio, shutdown/reboot and persistence. Do not install to a disk until a future installer has explicit safeguards and has been tested independently.
