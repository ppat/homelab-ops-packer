#!/bin/bash
set -eo pipefail

# read the name of the called script (which would be a symlink to this script)
CALLED_SYMLINK="$(basename "$0")"
TARGET_ARCH="$(echo $CALLED_SYMLINK | cut -d'.' -f2)"
CURRENT_ARCH="$(dpkg --print-architecture)"

export ANSIBLE_FORCE_COLOR=1
export PYTHONUNBUFFERED=1

if [[ "$CURRENT_ARCH" == "$TARGET_ARCH" ]]; then
  ansible-playbook "$@"
else
  if [[ "$TARGET_ARCH" == "arm64" ]]; then
    /usr/bin/qemu-aarch64-static ansible-playbook "$@"
  else
    /usr/bin/qemu-x86_64-static ansible-playbook "$@"
  fi
fi
