# BanaOS

BanaOS is an experimental x86_64 desktop Linux remaster based on Tiny Core Linux CorePure64 17.1. The first desktop target is Windows-inspired: a bottom taskbar, Start-style menu, file manager, terminal and compact application launcher.

> **Engineering preview:** this repository contains the build foundation. A successful configuration test is not proof of a bootable desktop. The ISO must pass CI and BIOS/UEFI virtual-machine testing before being called usable.

## Goals
- x86_64 PCs; live ISO first.
- Tiny Core modular extension system and minimal runtime footprint.
- JWM desktop with PCManFM, LXTerminal and Wbar.
- Reproducible build, checksum verification and downloadable CI artifacts.
- No destructive installer in the first milestone.

## Build on Ubuntu 24.04
```bash
sudo apt-get update
sudo apt-get install -y xorriso curl wget
bash tests/test-config.sh
bash build/build-iso.sh
```

Output: `dist/BanaOS-0.1.0-x86_64.iso`, SHA-256 file and build manifest.

The build downloads the official CorePure64 base image and resolves Tiny Core extension dependencies recursively. Set `BASE_ISO=/path/to/CorePure64-17.1.iso` to use a local ISO. Upstream MD5 verification is enabled by default. `SKIP_MD5=1` is an explicit override and should only be used after independent verification.

## Current limitations
- This is a live image, not an installer.
- BIOS/UEFI boot, persistence, device support and desktop startup still require VM and physical-hardware validation.
- No updater, recovery environment or disk partitioning tool is included.
- BanaOS is an independent remaster, not an official Tiny Core release.

See [docs/ROADMAP.md](docs/ROADMAP.md), [docs/BUILDING.md](docs/BUILDING.md) and [docs/TESTING.md](docs/TESTING.md). Tiny Core and included extensions retain their upstream licenses; BanaOS scripts/configuration are MIT-licensed.
