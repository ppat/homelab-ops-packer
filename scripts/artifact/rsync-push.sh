#!/bin/bash
set -euo pipefail

push() {
  local username=$1
  local password=$2
  local host=$3
  local source=$4
  local destination=$5

  echo Testing connectivity to $host:22
  nc -z -v -w 1 $host 22
  echo

  local rsync_password_file="$(mktemp)"
  echo $password > $rsync_password_file
  trap "rm -f $rsync_password_file" EXIT

  echo '**************************************************************************************'
  echo "===> Publishing artifact(s) via rsync: $source -> $host:$destination"
  rsync \
    --recursive \
    --checksum \
    --perms \
    --times \
    --progress \
    --stats \
    --verbose \
    --rsh="/usr/bin/sshpass -f $rsync_password_file ssh -o StrictHostKeyChecking=no -l $username" \
    $source \
    $username@$host:$destination
  echo '**************************************************************************************'
}

USERNAME=""
PASSWORD=""
HOST=""
SOURCE=""
DEST=""
# accept input parameters
while [ $# -gt 0 ]; do
  case "$1" in
    --username)
      USERNAME="$2"; shift
      ;;
    --password)
      PASSWORD="$2"; shift
      ;;
    --host)
      HOST="$2"; shift
      ;;
    --source)
      SOURCE="$2"; shift
      ;;
    --dest)
      DEST="$2"; shift
      ;;
    *)
      echo "Invalid parameter: ${1}"; echo; exit 1
  esac
  shift
done

if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$HOST" || -z "$SOURCE" || -z "$DEST" ]]; then
  echo "All parameters (--username, --password, --host, --source, --des) required!"
  exit 1
fi

push $USERNAME $PASSWORD $HOST $SOURCE $DEST
