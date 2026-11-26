# Building BanaOS

## Requirements
Ubuntu 24.04 x86_64, Bash, curl, wget, xorriso, grub-efi-amd64-bin, mtools, dosfstools, tar, awk, sed, md5sum and sha256sum.

## Build
```bash
bash tests/test-config.sh
bash -n build/build-iso.sh
bash build/build-iso.sh
```

The builder downloads CorePure64 17.1 from an HTTPS mirror, verifies its published MD5, resolves requested Tiny Core extensions and their dependencies recursively, checks extension MD5 files when published, and adds the extension cache and mydata backup to the CD extension directory. It then updates the original ISO tree with xorriso and replays the source BIOS boot settings and adds a GRUB x86_64 EFI System Partition, producing BIOS and UEFI El Torito entries.

## Environment
- BASE_ISO: use a local CorePure64 ISO.
- WORK_DIR, DIST_DIR, CACHE_DIR: override build paths.
- TC_MIRROR_ROOTS: space-separated HTTPS mirror roots.
- SKIP_MD5=1: explicit opt-out from base ISO MD5 verification; only use after independent verification.

## Output
dist/BanaOS-0.1.1-x86_64.iso, SHA-256 checksum, boot report and build manifest.
