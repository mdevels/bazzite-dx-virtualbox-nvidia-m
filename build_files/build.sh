#!/bin/bash
set -ouex pipefail

# --- Base packages you want in your image ---
dnf5 install -y tmux
dnf5 install -y \
  chromium \
  ddrescue \
  partclone \
  kde-partitionmanager \
  kompare \
  konsole \
  krusader

# Example service enablement
systemctl enable podman.socket

# --- VirtualBox install/build logic (self-contained, no external curl script dependency) ---

# Fedora release in container
RELEASE="$(rpm -E %fedora)"

# kernel version from installed kernel pkg (not uname -r in container)
KERNEL_VER="$(rpm -qa | grep -E 'kernel-[0-9].*?[.\-]' | cut -d'-' -f2,3 | head -n1)"

# Ensure prerequisites
dnf5 install -y dkms curl ca-certificates grep sed coreutils kmod

# Get latest VirtualBox release
VIRTUALBOX_VER="$(curl -fsSL https://download.virtualbox.org/virtualbox/LATEST.TXT)"
VIRTUALBOX_VER_URL="https://download.virtualbox.org/virtualbox/${VIRTUALBOX_VER}/"

# Pick newest VBox RPM compatible with current Fedora release
VIRTUALBOX_RPM="$(
  curl -fsSL "$VIRTUALBOX_VER_URL" \
    | grep -E -o 'VirtualBox[^"]+fedora[0-9]+-[^"]+\.x86_64\.rpm' \
    | sed -E 's/.*(VirtualBox.*\.rpm).*/\1/' \
    | sort -Vr \
    | while read -r rpm; do
        fedora_ver="$(echo "$rpm" | grep -E -o 'fedora[0-9]+' | grep -E -o '[0-9]+')"
        if [[ "$fedora_ver" -le "$RELEASE" ]]; then
          echo "$rpm"
          break
        fi
      done
)"

if [[ -z "${VIRTUALBOX_RPM:-}" ]]; then
  echo "No compatible VirtualBox Fedora RPM found for Fedora ${RELEASE}"
  exit 1
fi

VIRTUALBOX_RPM_URL="${VIRTUALBOX_VER_URL}${VIRTUALBOX_RPM}"
echo "Using '${VIRTUALBOX_RPM_URL}' for Fedora ${RELEASE}"

curl -fsSL -o "/tmp/${VIRTUALBOX_RPM}" "${VIRTUALBOX_RPM_URL}"
dnf5 install -y "/tmp/${VIRTUALBOX_RPM}"

# Hardcode kernel version so VBox doesn't try host runner kernel
vbox_hardcode_kv() {
  local TARGET_FILE="$1"
  local EXPR_UNAME_R="s/uname -r/echo '${KERNEL_VER}'/g"
  local EXPR_DEPMOD_A="s/depmod -a/depmod -v '${KERNEL_VER}' -a/g"
  sed -i -e "$EXPR_UNAME_R" -e "$EXPR_DEPMOD_A" "$TARGET_FILE"
}

vbox_hardcode_kv /usr/lib/virtualbox/vboxdrv.sh
vbox_hardcode_kv /usr/lib/virtualbox/check_module_dependencies.sh

KERN_VER="${KERNEL_VER}" /sbin/vboxconfig || true

if [[ -e /var/log/vbox-setup.log ]]; then
  cat /var/log/vbox-setup.log
fi

# Cleanup caches last
dnf5 clean all
rm -rf /var/cache/dnf /var/cache/yum /tmp/*
