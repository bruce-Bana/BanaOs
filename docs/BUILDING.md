# Building BanaOS

Recommended host: Ubuntu 24.04 x86_64 with bash, curl, wget, xorriso, tar, awk, sed, md5sum and sha256sum.

```bash
sudo apt-get update
sudo apt-get install -y xorriso curl wget
bash tests/test-config.sh
bash -n build/build-iso.sh
bash build/build-iso.sh
```

Environment overrides: `BASE_ISO`, `WORK_DIR`, `DIST_DIR`, `CACHE_DIR`, `TC_REPO`, and `SKIP_MD5=1`. The last option bypasses the upstream base-ISO MD5 check and must be used cautiously.

The build fetches the base ISO, verifies it, fetches requested Tiny Core extensions and dependency metadata, extracts the ISO with xorriso, adds the extension cache and Tiny Core home backup, then repacks the ISO. Output is in `dist/`.
