# BanaOS roadmap

## Foundation
- [x] Pin Tiny Core CorePure64 17.1 x86_64 baseline.
- [x] Add JWM desktop configuration and CI workflow.
- [ ] Complete and run the recursive extension build.
- [ ] Publish first ISO artifact after CI succeeds.

## Bootable desktop
- [ ] Boot in QEMU with legacy BIOS and UEFI/OVMF.
- [ ] Verify Xorg, JWM, menu, taskbar, PCManFM and LXTerminal.
- [ ] Verify keyboard, mouse, display resizing, networking and storage.
- [ ] Verify Tiny Core backup/persistence.
- [ ] Test at least two physical x86_64 computers.

## Usability
- [ ] BanaOS icon theme, wallpaper, shortcuts and polished menu.
- [ ] First-boot setup and network status.
- [ ] Friendly package/extension manager.
- [ ] Power, restart, logout and recovery flows.

## Installer and updates
- [ ] Safe installer with explicit disk selection and confirmation.
- [ ] Signed/checksummed updates and rollback.
- [ ] Rescue boot option and recovery documentation.

A release is not stable until CI builds it and BIOS/UEFI boot tests pass.
