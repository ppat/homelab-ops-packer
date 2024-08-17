#!/bin/bash
set -eo pipefail

echo '**************************************************************************************'
if [[ -f /etc/resolv.conf ]]; then
  rm /etc/resolv.conf
fi
echo '===> Cleaning up...'

echo '====> Cleaning up after apt...'
export DEBIAN_FRONTEND=noninteractive
echo '======> Autoremoving apt-get packages...'
apt-get autoremove -y
echo '======> Cleaning apt-get packages...'
apt-get clean -y
echo '======> Cleaning apt lists...'
find /var/lib/apt/lists/* -type f -delete
echo '====> Removing kernel backups...'
find /boot/firmware/* -name '*.bak' -print -delete
echo '====> Cleaning temp python artifacts (from having run ansible)...'
find /usr -type f -iname '*.pyc' -delete || echo 'could not delete all pyc files...'
# shellcheck disable=SC2038
find /usr -type d -name '__pycache__' -print | xargs rm -rf
echo '====> Cleaning misc artifacts...'
find /var -type f -iname '*.log' -delete || echo 'could not delete log files...'
rm -rf /tmp/* /var/tmp/* /var/cache/* /var/log/journal/* /root/.cache /root/.ansible /root/.local /root/.bash_history
echo ''
echo '**************************************************************************************'
