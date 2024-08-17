variable "ansible_params" {
  type    = map(string)
  default = {}
}

// variable "artifact_dir" {
//   type    = string
//   default = "${env("ARTIFACT_DIR")}"
// }

// variable "artifact_expected_size" {
//   type    = string
//   default = "5G"
// }

variable "dns_server" {
  type    = string
  default = "1.1.1.1"
}

// variable "src_image" {
//   type = object({
//     image_path      = string
//     checksum_path   = string
//     image_size      = string
//     partition_table = string
//     partitions = object({
//       boot = object({
//         filesystem   = string
//         start_sector = string
//         size         = string
//       })
//       root = object({
//         filesystem   = string
//         start_sector = string
//         size         = string
//       })
//     })
//   })
// }

variable "target_architecture" {
  type = string
}

variable "target_device" {
  type    = string
  default = "any"
}

// variable "temp_dir" {
//   type    = string
//   default = "${env("ARTIFACT_DIR")}/.temp"
// }

variable "ubuntu_release" {
  type = string
}

variable "image_dir" {
  type    = string
  default = "${env("HOME")}/.cache/images"
}
