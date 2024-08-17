#!/bin/bash
export ANSIBLE_FORCE_COLOR=1
export PYTHONUNBUFFERED=1

set -x
ansible-playbook "$@"
set +x
