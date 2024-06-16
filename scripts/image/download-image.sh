#!/bin/bash
set -euo pipefail


_download_from_upstream() {
  local release_url=$1
  local checksum_url=$2
  local download_file=$3
  local download_dir=$4

  echo "Downloading ${download_file}..."
  wget -nv --continue -O "${download_dir}/${download_file}" ${release_url}
  echo "Downloading checksums..."
  wget -O "${download_dir}/${download_file}_SHA256SUMS" ${checksum_url}
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
