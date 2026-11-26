# BanaOS

BanaOS is an experimental x86_64 desktop Linux remaster based on Tiny Core Linux CorePure64 17.1. Its initial desktop uses JWM with a Windows-inspired bottom taskbar and Start menu, PCManFM file manager, LXTerminal and Wbar.

> **Engineering preview:** the source and CI pipeline are prepared. The ISO is not considered a usable release until the automated build succeeds and BIOS/UEFI boot tests have been completed.

## Design goals
- 64-bit x86 PCs only; live ISO first.
- Tiny Core's small modular base and extension system.
- JWM desktop, familiar taskbar/menu, file manager and terminal.
- Dependency-closed extension set with published checksum verification.
- Reproducible build with downloadable ISO and SHA-256 manifest.
- No destructive installer in this first milestone.

## Build on Ubuntu 24.04
```bash
sudo apt-get update
sudo apt-get install -y xorriso curl wget
bash tests/test-config.sh
bash build/build-iso.sh
```

Output: `dist/BanaOS-0.1.0-x86_64.iso`, SHA-256 file, boot report and manifest. The build tries multiple HTTPS mirrors, verifies the upstream CorePure64 ISO using its published MD5 file, recursively downloads extension dependencies, and preserves the original ISO boot structures with xorriso.

## Boot
Use a trusted USB imaging tool or a virtual machine. This is a **live ISO only**; no disk installer is included. Back up important data before testing boot media.

## Current limitations
- BIOS/UEFI firmware boot and hardware compatibility still need testing.
- Desktop auto-start and persistence must be verified on real and virtual machines.
- No graphical installer, updater, recovery environment or signed release system yet.
- BanaOS is an independent remaster, not an official Tiny Core release.

## License
BanaOS scripts/configuration are MIT-licensed. Tiny Core Linux and included extensions retain their own upstream licenses and notices.
