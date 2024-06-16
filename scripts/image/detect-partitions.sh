#!/bin/bash
set -euo pipefail

TEMP=${WORK_DIR:-/tmp}

########## Regex for extracting data from 'parted'
#                   number     start       end         size        other-fields
PARTITION_REGEX='^\s*([0-9]+)\s+([0-9]+)B\s+([0-9]+)B\s+([0-9]+)B\s+(.+)$'
SECTOR_REGEX='^Sector size .*\: ([0-9]+)B.+$'
IMAGE_SIZE_REGEX='^Disk .*\: ([0-9]+)B$'
PART_TABLE_TYPE_REGEX='^Partition Table: ([0-9a-zA-Z]+)$'
GPT_FILESYSTEM_TYPE_REGEX='^([0-9a-zA-Z]+)\s*(.*)$'
MSDOS_FILESYSTEM_TYPE_REGEX='^([0-9a-zA-Z]+)\s+([0-9a-zA-Z]+)(.*)$'

eval_sed_expr() {
  local text=$1
  local sed_expr=$2
  eval "echo \"${text}\" | sed -r -n ${sed_expr}"
}

extract_partition_field() {
  local partition=$1
  local field=$2
  local sed_expr=$(printf "'s|%s|\%s|p'" ${PARTITION_REGEX} ${field})
  eval_sed_expr "${partition}" "${sed_expr}"
}

detect_filesystem() {
  local partition=$1
  local partition_table=$2

  local other_fields=$(extract_partition_field "${partition}" 5)
  if [[ "${partition_table}" == "msdos" ]]; then
    eval_sed_expr "${other_fields}" "'s|${MSDOS_FILESYSTEM_TYPE_REGEX}|\2|p'"
  elif [[ "${partition_table}" == "gpt" ]]; then
    eval_sed_expr "${other_fields}" "'s|${GPT_FILESYSTEM_TYPE_REGEX}|\1|p'"
  else
    echo "unsupported-${partition_table}"
    exit 1
  fi
}

detect_start_sector() {
  local partition=$1
  local sector_size=$2
  local start_byte=$(extract_partition_field "${partition}" 2)
  echo $(( start_byte / sector_size ))
}

detect_partition_size() {
  local partition=$1
  extract_partition_field "${partition}" 4
}

bytes_to_mib() {
  echo "$(( $1 / (1024*1024) ))M"
}

detect_partitions() {
  local img_file=$1
  local part_info="${TEMP}/partition_info"
  parted ${img_file} unit B print > ${part_info}

  local sector_size=$(eval_sed_expr "$(cat ${part_info})" "'s|${SECTOR_REGEX}|\1|p'")
  local partition_table="$(eval_sed_expr "$(cat ${part_info})" "'s|${PART_TABLE_TYPE_REGEX}|\1|p'")"
  if [[ "${partition_table}" != "msdos" && "${partition_table}" != "gpt" ]]; then
    echo "unsupported partition table: ${partition_table}"
    exit 1
  fi

  local boot_partition_filter="boot"
  if [[ "${partition_table}" == "gpt" ]]; then
    boot_partition_filter="boot, esp"
  fi
  local boot_partition=$(cat ${part_info} | grep -E "${PARTITION_REGEX}" | grep "${boot_partition_filter}")
  local root_partition=$(cat ${part_info} | grep -E "${PARTITION_REGEX}" | grep -v "boot" | tail -1)

  cat <<EOF
src_image = {
  image_path = "${img_file}"
  checksum_path = "${img_file}_SHA256SUMS"
  image_size = "$(bytes_to_mib $(eval_sed_expr "$(cat ${part_info})" "'s|${IMAGE_SIZE_REGEX}|\1|p'"))"
  partition_table = "${partition_table}"
  partitions = {
    boot = {
      filesystem = "$(detect_filesystem "${boot_partition}" "${partition_table}")"
      start_sector = "$(detect_start_sector "${boot_partition}" ${sector_size})"
      size = "$(bytes_to_mib $(detect_partition_size "${boot_partition}"))"
    }
    root = {
      filesystem = "$(detect_filesystem "${root_partition}" "${partition_table}")"
      start_sector = "$(detect_start_sector "${root_partition}" ${sector_size})"
      size = "$(bytes_to_mib $(detect_partition_size "${root_partition}"))"
    }
  }
}
EOF
}

detect_partitions $1
