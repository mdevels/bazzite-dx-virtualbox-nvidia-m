# bazzite-dx-virtualbox-nvidia-m

[![bazzite-dx-virtualbox-nvidia-m](https://github.com/mdevels/bazzite-dx-virtualbox-nvidia-m/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/mdevels/bazzite-dx-virtualbox-nvidia-m/actions/workflows/build.yml)

This is a slightly modified image of **bazzite-dx**.  
It was built using the [ublue-os image template](https://github.com/ublue-os/image-template) and [ettfemnio’s VirtualBox install script](https://github.com/ettfemnio/bazzite-virtualbox/).  
The base image is **bazzite-dx-nvidia** (KDE Plasma).

---

# Changes to the OOTB bazzite-dx-nvidia image

- VirtualBox, its kernel drivers, and the Extension Pack installed  
- Extra disk utilities: `ddrescue`, `partclone`  
- Extra KDE packages: `kde-partitionmanager`, `kompare`, `konsole`, `krusader`  
- Non‑sandboxed Chromium installed (for WebSerial support)

---

# Usage

Rebase manually:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/mdevels/bazzite-dx-virtualbox-nvidia-m
```

---

# Credits

[Ettfemnio’s VirtualBox install script](https://github.com/ettfemnio/bazzite-virtualbox/) does the heavy lifting here — full credit to him.

---

# License Info

By using this image, you agree to the terms of the  
[Oracle VirtualBox Extension Pack Personal Use and Education License](https://www.virtualbox.org/wiki/VirtualBox_PUEL).

