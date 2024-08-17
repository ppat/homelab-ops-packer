#!/bin/bash
set -eo pipefail

# read the name of the called script (which would be a symlink to this script)
CALLED_SYMLINK="$(basename "$0")"
TARGET_SCRIPT="$(dirname "$0")/$(echo $CALLED_SYMLINK | cut -d'.' -f1).sh"
TARGET_ARCH="$(echo $CALLED_SCRIPT | cut -d'.' -f1 | cut -d'-' -f2)"
CURRENT_ARCH="$(dpkg --print-architecture)"

if [[ "$CURRENT_ARCH" == "$TARGET_ARCH" ]]; then
  echo "Current architecture ($CURRENT_ARCH) matches target architecture ($TARGET_ARCH), no emulation needed."
  set -x
  ${TARGET_SCRIPT} "$@"
  set +x
else
  echo "Current architecture ($CURRENT_ARCH) does NOT match target architecture ($TARGET_ARCH), emulation is needed."
  if [[ "$TARGET_ARCH" == "arm64" ]]; then
    set -x
    /usr/bin/qemu-aarch64-static ${TARGET_SCRIPT} "$@"
    set +x
  else
    set -x
    /usr/bin/qemu-x86_64-static ${TARGET_SCRIPT} "$@"
    set +x
  fi
fi
