# BanaOS roadmap

## Build foundation
- [x] Pin Tiny Core CorePure64 17.1 x86_64.
- [x] Configure JWM desktop and Windows-inspired taskbar/menu.
- [x] Resolve extension dependencies recursively.
- [x] Add HTTPS mirror fallback and upstream checksum verification.
- [x] Preserve original ISO boot structures and verify the boot catalog.
- [ ] Complete a successful CI ISO build and publish its artifact.

## Bootable desktop
- [ ] Test BIOS boot in QEMU.
- [ ] Test UEFI boot in QEMU/OVMF if supported by the base ISO.
- [ ] Verify Xorg auto-start, JWM, menu, taskbar, PCManFM and LXTerminal.
- [ ] Verify keyboard, mouse, display, networking, audio and storage.
- [ ] Verify backup/persistence and shutdown.
- [ ] Test at least two physical x86_64 PCs.

## Usability
- [ ] BanaOS icon theme, wallpaper, shortcuts and polished app menu.
- [ ] First-boot setup and network status.
- [ ] User-friendly package/extension manager.
- [ ] Power, restart, logout and recovery flows.

## Installer and updates
- [ ] Safe installer with explicit disk selection and destructive-action confirmation.
- [ ] Signed/checksummed update system with rollback.
- [ ] Rescue/recovery boot option.

A release is not stable until CI builds the ISO and boot/persistence tests pass.
