build {
  sources = [
    // "source.arm.ubuntu",
    "source.null.chroot"
  ]

  # ------------------------------------ prepare ----------------------------------------
  provisioner "shell-local" {
    env = {
      ROOT_MOUNT_PATH = local.chroot_path
      BOOT_MOUNT_PATH = (var.target_architecture == "arm64") ? "/boot/firmware" : "-"
      OUTPUT_DIR      = var.image_dir
      DNS_SERVER      = var.dns_server
    }
    inline = [
      "mkdir -p $OUTPUT_DIR",
      "mkdir -p $ROOT_MOUNT_PATH",
      "echo '**************************************************************************************'",
      "echo '===> Fetching image...'",
      "sudo ${path.root}/scripts/fetch-image.sh --url ${local.image_url} --output-dir $OUTPUT_DIR --timeout 2m --retries 10",
      "echo '**************************************************************************************'",
      "echo '===> Mounting image...'",
      "sudo ${path.root}/scripts/mount-image.sh --image /tmp/fetched_image --root-mountpoint $ROOT_MOUNT_PATH --boot-mountpoint $BOOT_MOUNT_PATH",
      "echo '**************************************************************************************'",
      "echo '===> Enabling DNS resolution (for apt-get)...'",
      "rm -f $ROOT_MOUNT_PATH/etc/resolv.conf",
      "echo \"nameserver $DNS_SERVER\" > $ROOT_MOUNT_PATH/etc/resolv.conf",
      "echo '**************************************************************************************'",
    ]
  }
  # -------------------------------------------------------------------------------------


  # ----------------------------------- provision ---------------------------------------
  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/playbook.yaml"
    galaxy_file   = "${path.root}/ansible/requirements.yaml"

    # see: https://github.com/mkaczanowski/packer-builder-arm/issues/121
    inventory_file_template = "default ansible_host=${local.chroot_path} ansible_connection=chroot\n"
    extra_arguments = concat(
      [for k, v in var.ansible_params : "-e ${k}=${v}"],
      [
        "-e device_type=${var.target_device}",
        "--verbose"
      ]
    )
  }

  provisioner "shell-local" {
    env = {
      CHROOT_PATH   = local.chroot_path
      TARGET_ARCH   = var.target_architecture
      FILES         = "${path.root}/scripts/cleanup.sh"
      TARGET_SCRIPT = "cleanup.sh"
    }
    inline = [
      "echo '**************************************************************************************'",
      "echo '===> Cleaning up...'",
      "sudo ${path.root}/scripts/chroot-invoke.sh",
      "echo '**************************************************************************************'",
    ]
  }
  # -------------------------------------------------------------------------------------


  # -------------------------------- create images -------------------------------------
  provisioner "shell-local" {
    env = {
      EXCLUDES_LIST     = "${path.root}/../scripts/artifact/image-excludes.list"
      ROOT_MOUNT_PATH   = local.chroot_path
      BOOT_MOUNT_PATH   = (var.target_architecture == "arm64") ? "/boot/firmware" : "/boot"
      TEMP_ARTIFACT_DIR = var.temp_dir
      ROOT_ARTIFACT     = "${var.temp_dir}/${local.build_root_artifact}"
      BOOT_ARTIFACT     = "${var.temp_dir}/${local.build_boot_artifact}"
    }
    inline = [
      "echo '**************************************************************************************'",
      "echo '===> Creating artifacts...'",
      "mkdir -p $TEMP_ARTIFACT_DIR",
      "export ZSTD_NBTHREADS=4",
      "export ZSTD_CLEVEL=3",
      "echo '=====> Root artifact'",
      "tar --exclude-from $EXCLUDES_LIST --zstd -C $ROOT_MOUNT_PATH -cf $ROOT_ARTIFACT ./",
      "echo '=====> Boot artifact'",
      "tar --exclude-from $EXCLUDES_LIST --zstd -C $BOOT_MOUNT_PATH -cf $BOOT_ARTIFACT ./",
      "echo '**************************************************************************************'"
    ]
  }
  provisioner "file" {
    sources = [
      "${var.temp_dir}/${local.build_root_artifact}",
      "${var.temp_dir}/${local.build_boot_artifact}"
    ]
    destination = "${local.artifact_output_path}/"
    direction   = "download"
  }
  # -------------------------------------------------------------------------------------


  # ------------------------------ checksum + manifest ----------------------------------
  post-processors {
    post-processor "artifice" {
      files = [
        "${local.artifact_output_path}/${local.build_root_artifact}",
        "${local.artifact_output_path}/${local.build_boot_artifact}"
      ]
      keep_input_artifact = false
    }
    post-processor "checksum" {
      checksum_types      = ["sha256"]
      output              = "${local.artifact_output_path}/${local.build_checksum}"
      keep_input_artifact = true
    }
    post-processor "manifest" {
      output     = "${local.artifact_output_path}/manifest-${local.build_basename}.json"
      strip_path = true
      custom_data = {
        os            = "ubuntu"
        version       = var.ubuntu_release
        arch          = var.target_architecture
        device_type   = var.target_device
        timestamp     = local.build_timestamp
        basename      = local.build_basename
        artifact_path = local.build_artifact_path
      }
    }
  }
  # -------------------------------------------------------------------------------------

}
