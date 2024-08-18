// source "arm" "ubuntu" {
//   file_checksum_url     = var.src_image["checksum_path"]
//   file_urls             = [var.src_image["image_path"]]
//   file_checksum_type    = "sha256"
//   file_target_extension = "img"

//   image_build_method = "resize"
//   image_chroot_env   = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
//   image_mount_path   = local.chroot_path
//   image_path         = "${var.artifact_dir}/${local.build_basename}.img"
//   image_size         = var.artifact_expected_size
//   image_type         = var.src_image["partition_table"] == "msdos" ? "dos" : var.src_image["partition_table"]

//   image_partitions {
//     mountpoint   = local.boot_firmware_source_path
//     name         = "boot"
//     filesystem   = var.src_image["partitions"]["boot"]["filesystem"] == "fat32" ? "fat" : var.src_image["partitions"]["boot"]["filesystem"]
//     size         = var.src_image["partitions"]["boot"]["size"]
//     start_sector = var.src_image["partitions"]["boot"]["start_sector"]
//     type         = "c"
//   }
//   image_partitions {
//     mountpoint   = "/"
//     name         = "root"
//     filesystem   = var.src_image["partitions"]["root"]["filesystem"] == "fat32" ? "fat" : var.src_image["partitions"]["root"]["filesystem"]
//     size         = 0
//     start_sector = var.src_image["partitions"]["root"]["start_sector"]
//     type         = "83"
//   }

//   qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
//   qemu_binary_source_path      = "/usr/bin/qemu-aarch64-static"
// }

source "null" "chroot" {
  communicator = "none"
}
