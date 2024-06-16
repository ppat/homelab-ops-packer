#!/bin/bash
set -euo pipefail

CURRENT_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=$(dirname $CURRENT_SCRIPT_DIR)

RELEASE_URL='https://cdimage.ubuntu.com/ubuntu-server/%s/daily-preinstalled/current/%s-preinstalled-server-%s.img.xz'
RELEASE_SHA_URL='https://cdimage.ubuntu.com/ubuntu-server/%s/daily-preinstalled/current/SHA256SUMS'


create_config_from_download() {
  local release_url=$1
  local checksum_url=$2
  local image_file_path=$3
  local config_file_path=$4

  ${PARENT_DIR}/image/download-image.sh --release-url $release_url --checksum-url $checksum_url --output-file-path $image_file_path
  ${PARENT_DIR}/image/detect-partitions.sh $image_file_path > $config_file_path
}

update_config_file() {
  local config_file_path=$1
  local code_name=$2
  local arch_plus_device_type=$3
  local arch="$(echo $arch_plus_device_type | cut -d+ -f1)"
  local device_type="$(echo $arch_plus_device_type | cut -d+ -f2)"

  if [[ "$arch" == "$device_type" ]]; then
    device_type="any"
  fi

  {
    echo "ubuntu_code_name = \"${code_name}\""
    echo "target_architecture = \"${arch}\""
    echo "target_device = \"${device_type}\""
  } >> ${config_file_path}
}

display_config() {
  local config_file_path=$1

  echo
  echo "Using source image configuration: "
  cat ${config_file_path} | pr -o 4 -t
  echo
}

create_source_config() {
  local code_name=$1
  local arch=$2
  local image_file=$3
  local config_file=$4

  local release_url=$(printf "${RELEASE_URL}" ${code_name} ${code_name} ${arch})
  local checksum_url=$(printf "${RELEASE_SHA_URL}" ${code_name})

  create_config_from_download $release_url $checksum_url $image_file $config_file
  update_config_file $config_file $code_name $arch
  display_config $config_file
}

main() {
  local code_name=$1
  local arch=$2
  local download_dir=$3
  local config_dir=$4

  mkdir -p $download_dir
  mkdir -p $config_dir

  local timestamp="$(date +%Y%m%d%H%M%S)"
  local image_file="${download_dir}/${code_name}-${arch}-${timestamp}.img"
  local config_file="${config_dir}/source.pkrvars.hcl"

  create_source_config $code_name $arch $image_file $config_file
}


ARCH=""
CODE_NAME=""
DOWNLOAD_DIR=""
CONFIG_DIR=""
# accept input parameters
while [ $# -gt 0 ]; do
  case "$1" in
    --arch)
      ARCH="$2"; shift
      ;;
    --code-name)
      CODE_NAME="$2"; shift
      ;;
    --download-dir)
      DOWNLOAD_DIR="$2"; shift
      ;;
    --config-dir)
      CONFIG_DIR="$2"; shift
      ;;
    *)
      echo "Invalid parameter: ${1}"; echo; exit 1
  esac
  shift
done

if [[ -z "$ARCH" ]]; then
  echo "Architecture (--arch) is required!"
  exit 1
fi
if [[ -z "$CODE_NAME" ]]; then
  echo "Ubuntu release code name (--code-name) is required!"
  exit 1
fi
if [[ -z "$DOWNLOAD_DIR" ]]; then
  echo "Download directory (--download-dir) is required!"
  exit 1
fi
if [[ -z "$CONFIG_DIR" ]]; then
  echo "Config directory (--config-dir) is required!"
  exit 1
fi

main $CODE_NAME $ARCH $DOWNLOAD_DIR $CONFIG_DIR
