#!/bin/bash

set -ouex pipefail

PS4='+ [${BASH_SOURCE##*/}:${LINENO}] '
set -x
trap 'echo "FAILED at ${BASH_SOURCE##*/}:${LINENO}: ${BASH_COMMAND}" >&2' ERR

### 1. Install standard Fedora packages
dnf5 install -y tmux 
dnf5 install -y \
  chromium \
  ddrescue \
  partclone \
  kde-partitionmanager \
  kompare \
  krusader \
  wavemon \
  wireshark

# Enable Podman socket
systemctl enable podman.socket

### 2. Install VirtualBox & Kernel Modules from RPM Fusion
### 2. Install VirtualBox & Kernel Modules from RPM Fusion
KERNEL_VER=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel | head -n 1)

RPMFUSION_MIRROR="mirrors.rpmfusion.org"
dnf5 install -y \
  "https://${RPMFUSION_MIRROR}/free/fedora/rpmfusion-free-release-45.noarch.rpm" \
  "https://${RPMFUSION_MIRROR}/nonfree/fedora/rpmfusion-nonfree-release-45.noarch.rpm"

dnf5 install -y VirtualBox akmod-VirtualBox "kernel-devel-${KERNEL_VER}"

akmods --force --kernels "${KERNEL_VER}"

### 3. Install Matching Oracle VirtualBox Extension Pack
VBOX_VER=$(rpm -q --qf '%{VERSION}' VirtualBox)
EXTPACK_NAME="Oracle_VirtualBox_Extension_Pack-${VBOX_VER}.vbox-extpack"
VBOX_HOST="download.virtualbox.org"
EXTPACK_URL="https://${VBOX_HOST}/virtualbox/${VBOX_VER}/${EXTPACK_NAME}"
SUMS_URL="https://${VBOX_HOST}/virtualbox/${VBOX_VER}/SHA256SUMS"

curl -fL -o "/tmp/${EXTPACK_NAME}" "${EXTPACK_URL}"
HASH=$(curl -fsL "${SUMS_URL}" | grep "${EXTPACK_NAME}" | cut -d' ' -f1)

/usr/lib64/virtualbox/VBoxExtPackHelperApp install \
  --base-dir /usr/lib64/virtualbox/ExtensionPacks \
  --cert-dir /usr/share/virtualbox/ExtPackCertificates \
  --name "Oracle VirtualBox Extension Pack" \
  --tarball "/tmp/${EXTPACK_NAME}" \
  --sha-256 "${HASH}"

### 4. Auto-load VirtualBox kernel modules at boot
mkdir -p /usr/lib/modules-load.d
cat > /usr/lib/modules-load.d/bazzite-virtualbox.conf << EOF
vboxdrv
vboxnetflt
vboxnetadp
EOF

### 5. Clean up dnf caches
dnf5 clean all
rm -rf /var/cache/dnf /var/cache/yum
