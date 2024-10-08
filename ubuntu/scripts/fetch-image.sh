#!/bin/bash
set -euo pipefail

url_resolved_to_random_ip() {
  local url=$1
  local hostname="$(echo $url | sed -E -n 's|([a-z0-9]*\:\/\/)([^\\/]+)\/.*|\2|p')"
  local random_ip="$(dig +short $hostname | sort | sort --random-sort | head -1)"
  echo $url | sed -E -n 's|([a-z0-9]*\:\/\/)([^\\/]+)(\/.*)|\1'$random_ip'\3|p'
}

fetch_image() {
  local url=$1
  local output_file=$2
  local timeout=$3
  local retries=$4

  local attempt=0
  while [ $attempt -lt $retries ]; do
    echo "Attempt $attempt"
    local attempt_url="$(url_resolved_to_random_ip $url)"
    echo "    URL: $attempt_url"
    set +e
    /usr/bin/timeout --verbose $timeout wget \
      -nv \
      --connect-timeout=10 \
      --continue \
      --no-check-certificate \
      --output-document=${output_file} \
      $attempt_url
    exit_code=$?
    set -e
    if [[ $exit_code -eq 0 ]]; then
      echo "  Success"
      return 0
    elif [[ $exit_code -eq 124 ]]; then
      echo "  Timed out"
      attempt=$(( attempt + 1 ))
    else
      echo "  Failed"
      exit $exit_code
    fi
  done
}

main() {
  local url=$1
  local output_dir=$2
  local timeout=$3
  local retries=$4

  local output_file="${output_dir}/$(basename ${url})"
  local unpacked_file="${output_file%.*}"

  if [[ ! -f $unpacked_file ]]; then
    echo "Fetching image from $url..."
    fetch_image $url ${output_file} $timeout $retries
    echo
    echo "Unpacking image..."
    xz -d ${output_file}
    echo
  else
    echo "$unpacked_file already exists... skipping fetch."
  fi
  echo "Symlinking $unpacked_file to /tmp/fetched_image"
  ln -sf $unpacked_file /tmp/fetched_image
  echo
  echo "Done..."
}

OUTPUT_DIR=""
IMAGE_URL=""
TIMEOUT="5m"
RETRIES="3"

while [ $# -gt 0 ]; do
  case "$1" in
    --url)
      IMAGE_URL="$2"; shift
      ;;
    --output-dir)
      OUTPUT_DIR="$2"; shift
      ;;
    --timeout)
      TIMEOUT="$2"; shift
      ;;
    --retries)
      RETRIES="$2"; shift
      ;;
    *)
      echo "Invalid parameter: ${1}"; echo; exit 1
  esac
  shift
done

if [[ -z "$IMAGE_URL" || -z "$OUTPUT_DIR" ]]; then
  echo "--url and --output-dir are required."
  exit 1
fi

main ${IMAGE_URL:?} ${OUTPUT_DIR:?} ${TIMEOUT:?} ${RETRIES:?} 2>&1
