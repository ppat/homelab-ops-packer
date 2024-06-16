locals {
  build_timestamp     = formatdate("YYYYMMDDhhmm", timestamp())
  build_basename      = "${var.ubuntu_code_name}${var.target_device == "any" ? "" : format("-%s", var.target_device)}-${local.build_timestamp}"
  build_artifact_path = "ubuntu-${var.target_architecture}/${var.ubuntu_code_name}"
  build_root_artifact = "${local.build_basename}-rootfs.tar.zst"
  build_boot_artifact = "${local.build_basename}-bootfs.tar.zst"
  build_checksum      = "${local.build_basename}.SHA256SUMS"

  artifact_output_path      = "${var.artifact_dir}/${local.build_artifact_path}"
  boot_firmware_source_path = "/mnt/boot-firmware"
  chroot_path               = "${var.temp_dir}/packer_chroot"
  packer_root               = "${path.root}"
}
