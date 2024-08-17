#!/bin/bash
set -eo pipefail

TARGET_ARCH="$1"
TARGET_SCRIPT="$2"
CURRENT_ARCH="$(dpkg --print-architecture)"

mkdir -p $CHROOT_PATH/tmp/scripts
cp $TARGET_SCRIPT $CHROOT_PATH/tmp/scripts/

if [[ "$CURRENT_ARCH" == "$TARGET_ARCH" ]]; then
  echo "Current architecture ($CURRENT_ARCH) matches target architecture ($TARGET_ARCH), no emulation needed."
  set -x
  chroot $CHROOT_PATH /tmp/scripts/$TARGET_SCRIPT
  set +x
else
  echo "Current architecture ($CURRENT_ARCH) does NOT match target architecture ($TARGET_ARCH), emulation is needed."
  if [[ "$TARGET_ARCH" == "arm64" ]]; then
    set -x
    cp /usr/bin/qemu-aarch64-static /tmp/scripts/qemu-aarch64-static
    chroot $CHROOT_PATH /tmp/scripts/qemu-aarch64-static /tmp/scripts/$TARGET_SCRIPT
    set +x
  else
    set -x
    cp /usr/bin/qemu-x86_64-static /tmp/scripts/qemu-x86_64-static
    chroot $CHROOT_PATH /tmp/scripts/qemu-x86_64-static /tmp/scripts/$TARGET_SCRIPT
    set +x
  fi
fi
