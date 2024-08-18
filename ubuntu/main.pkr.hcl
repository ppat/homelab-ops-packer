locals {
  arch_plus_device_suffix = (var.target_device != "any") ? join("+", [var.target_architecture, var.target_device]) : var.target_architecture
  image_url               = "https://cdimage.ubuntu.com/ubuntu-server/${var.ubuntu_release}/daily-preinstalled/current/${var.ubuntu_release}-preinstalled-server-${local.arch_plus_device_suffix}.img.xz"

  build_timestamp     = formatdate("YYYYMMDDhhmm", timestamp())
  build_basename      = "${var.ubuntu_release}${var.target_device == "any" ? "" : format("-%s", var.target_device)}-${local.build_timestamp}"
  build_artifact_path = "ubuntu-${var.target_architecture}/${var.ubuntu_release}"
  build_root_artifact = "${local.build_basename}-rootfs.tar.zst"
  build_boot_artifact = "${local.build_basename}-bootfs.tar.zst"
  build_checksum      = "${local.build_basename}.SHA256SUMS"

  artifact_output_path = "${var.artifact_dir}/${local.build_artifact_path}"
  chroot_path          = "/tmp/${local.build_basename}"
}
