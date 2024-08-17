build {
  sources = [
    // "source.arm.ubuntu",
    "source.null.chroot"
  ]

  # ------------------------------------ prepare ----------------------------------------
  provisioner "shell-local" {
    env = {
      IMAGE_MOUNT_PATH = "/tmp/${local.build_basename}"
      OUTPUT_DIR = var.image_dir
    }
    only = [
      "null.chroot"
    ]
    inline = [
      "mkdir -p $OUTPUT_DIR",
      "mkdir -p $IMAGE_MOUNT_PATH",
      "sudo ${path.root}/scripts/fetch-image.sh --url ${local.image_url} --output-dir $OUTPUT_DIR --timeout 2m --retries 10",
      "sudo ${path.root}/scripts/mount-image.sh --image /tmp/fetched_image --root-mountpoint $IMAGE_MOUNT_PATH --boot-mountpoint /boot/firmware"
    ]
    // script = "${path.root}/scripts/setup-chroot.sh"
  }

  // provisioner "shell" {
  //   environment_vars = [
  //     "DNS_SERVER=${var.dns_server}",
  //   ]
  //   inline = [
  //     "echo '**************************************************************************************'",
  //     "echo '===> Enabling DNS resolution...'",
  //     "rm -f /etc/resolv.conf",
  //     "echo \"nameserver $DNS_SERVER\" > /etc/resolv.conf",
  //     "echo '**************************************************************************************'",
  //     "echo '===> Re-locating boot firmware...'",
  //     "mkdir -p /boot/firmware",
  //     "cp -R ${local.boot_firmware_source_path}/* /boot/firmware/",
  //     "echo '**************************************************************************************'"
  //   ]
  // }
  # -------------------------------------------------------------------------------------


  # ----------------------------------- provision ---------------------------------------
  // provisioner "ansible" {
  //   playbook_file = "${local.packer_root}/ansible/playbook.yaml"
  //   galaxy_file   = "${local.packer_root}/ansible/requirements.yaml"

  //   # see: https://github.com/mkaczanowski/packer-builder-arm/issues/121
  //   inventory_file_template = "default ansible_host=${local.chroot_path} ansible_connection=chroot\n"
  //   extra_arguments = concat(
  //     [for k, v in var.ansible_params : "-e ${k}=${v}"],
  //     [
  //       "-e device_type=${var.target_device}",
  //       "--verbose"
  //     ]
  //   )
  // }

  // provisioner "shell" {
  //   script = "${local.packer_root}/../scripts/ubuntu/cleanup.sh"
  // }
  # -------------------------------------------------------------------------------------


  # -------------------------------- create images -------------------------------------
  // provisioner "file" {
  //   source      = "${local.packer_root}/../scripts/artifact/image-excludes.list"
  //   destination = "/tmp/image-excludes.list"
  // }
  // provisioner "shell" {
  //   environment_vars = [
  //     "ARTIFACT_DIR=/tmp/${local.build_basename}",
  //     "ARTIFACT_NAME=${local.build_root_artifact}",
  //     "BOOT_ARTIFACT_NAME=${local.build_boot_artifact}",
  //     "EXCLUDES_LIST=/tmp/image-excludes.list"
  //   ]
  //   script = "${local.packer_root}/../scripts/artifact/create-image-artifacts.sh"
  // }
  // provisioner "file" {
  //   sources = [
  //     "/tmp/${local.build_basename}/${local.build_root_artifact}",
  //     "/tmp/${local.build_basename}/${local.build_boot_artifact}"
  //   ]
  //   destination = "${local.artifact_output_path}/"
  //   direction   = "download"
  // }
  # -------------------------------------------------------------------------------------


  # ------------------------------ checksum + manifest ----------------------------------
  // post-processors {
  //   post-processor "artifice" {
  //     files = [
  //       "${local.artifact_output_path}/${local.build_root_artifact}",
  //       "${local.artifact_output_path}/${local.build_boot_artifact}"
  //     ]
  //     keep_input_artifact = false
  //   }
  //   post-processor "checksum" {
  //     checksum_types      = ["sha256"]
  //     output              = "${local.artifact_output_path}/${local.build_checksum}"
  //     keep_input_artifact = true
  //   }
  //   post-processor "manifest" {
  //     output     = "${local.artifact_output_path}/manifest-${local.build_basename}.json"
  //     strip_path = true
  //     custom_data = {
  //       os            = "ubuntu"
  //       version       = var.ubuntu_code_name
  //       arch          = var.target_architecture
  //       device_type   = var.target_device
  //       timestamp     = local.build_timestamp
  //       basename      = local.build_basename
  //       artifact_path = local.build_artifact_path
  //     }
  //   }
  // }
  # -------------------------------------------------------------------------------------

}
