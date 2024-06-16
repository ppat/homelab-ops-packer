#!/bin/bash
set -euo pipefail

create_image() {
  local source_path=$1
  local output_file=$2

  export ZSTD_NBTHREADS=4
  export ZSTD_CLEVEL=3

  tar --exclude-from ${EXCLUDES_LIST} --zstd -C ${source_path} -cf ${output_file} ./
}

main() {
  local artifact_dir="$1"
  local artifact_name="$2"
  local boot_artifact_name="$3"

  echo '===> Creating images...'
  echo '=====> Root FS'
  create_image / "${artifact_dir}/${artifact_name}"
  echo
  echo '=====> Boot FS'
  create_image /boot/firmware "${artifact_dir}/${boot_artifact_name}"
  echo
}

echo '**************************************************************************************'
if [[ ! -d ${ARTIFACT_DIR} ]]; then
  echo '===> Creating artifact directory...'
  mkdir -p ${ARTIFACT_DIR}
fi
main ${ARTIFACT_DIR} ${ARTIFACT_NAME} ${BOOT_ARTIFACT_NAME} 2>&1
echo '**************************************************************************************'
