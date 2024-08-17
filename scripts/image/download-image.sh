#!/bin/bash
set -euo pipefail



url_resolved_to_random_ip() {
  local url=$1
  local hostname="$(echo $url | sed -E -n 's|([a-z0-9]*\:\/\/)([^\\/]+)\/.*|\2|p')"
  local random_ip="$(dig +short $hostname | sort --random-sort | head -1)"
  echo $url | sed -E -n 's|([a-z0-9]*\:\/\/)([^\\/]+)(\/.*)|\1'$random_ip'\3|p'
}

fetch_url() {
  local url=$1
  local output_file=$2
  local timeout=$3
  local retries=$4

  rm -f ${output_file}

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

_download_from_upstream() {
  local release_url=$1
  local checksum_url=$2
  local download_file=$3
  local download_dir=$4

  echo "Downloading ${download_file}..."
  fetch_url ${release_url} "${download_dir}/${download_file}" 2m 10
  echo "Downloading checksums..."
  fetch_url ${checksum_url} "${download_dir}/${download_file}_SHA256SUMS" 30s 10
  echo "Verifying checksum..."
  sha256sum --ignore-missing --check "${download_file}_SHA256SUMS"
}

download_image() {
  local output="$1"
  local release_url="$2"
  local checksum_url="$3"

  local download_dir=$(dirname ${output})
  local output_file=$(basename ${output})
  mkdir -p ${download_dir}
  pushd ${download_dir} 1> /dev/null

  local compressed_artifact_name="${release_url##*/}"
  local uncompressed_artifact_name="${compressed_artifact_name%.*}"

  if [[ ! -f "${output}" ]]; then
    echo "Fetching ${release_url}..."
    if [[ ! -f "${download_dir}/${compressed_artifact_name}" ]]; then
      _download_from_upstream "${release_url}" "${checksum_url}" "${compressed_artifact_name}" "${download_dir}"
    else
      echo "Compressed artifact is available locally..."
    fi
    echo "Uncompressing..."
    xz --decompress --keep ${compressed_artifact_name}
    mv "${download_dir}/${uncompressed_artifact_name}" "${output}"
    echo "Creating checksum file for uncompressed image..."
    sha256sum --binary "${output_file}" > "${output_file}_SHA256SUMS"
  else
    echo "Using existing downloaded image: ${output}"
  fi

  popd 1> /dev/null
  echo
}


RELEASE_URL=""
CHECKSUM_URL=""
OUTPUT_FILE_PATH=""
# accept input parameters
while [ $# -gt 0 ]; do
  case "$1" in
    --release-url)
      RELEASE_URL="$2"; shift
      ;;
    --checksum-url)
      CHECKSUM_URL="$2"; shift
      ;;
    --output-file-path)
      OUTPUT_FILE_PATH="$2"; shift
      ;;
    *)
      echo "Invalid parameter: ${1}"; echo; exit 1
  esac
  shift
done

if [[ -z "$RELEASE_URL" ]]; then
  echo "Release URL (--release-url) is required!"
  exit 1
fi
if [[ -z "$CHECKSUM_URL" ]]; then
  echo "Checksum URL (--checksum-url) is required!"
  exit 1
fi
if [[ -z "$OUTPUT_FILE_PATH" ]]; then
  echo "Full path to downloaded image file (--output-file-path) is required!"
  exit 1
fi

download_image $OUTPUT_FILE_PATH $RELEASE_URL $CHECKSUM_URL
