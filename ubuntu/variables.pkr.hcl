variable "ansible_params" {
  type    = map(string)
  default = {}
}

variable "artifact_dir" {
  type    = string
  default = "${env("ARTIFACT_DIR")}"
}

variable "dns_server" {
  type    = string
  default = "1.1.1.1"
}

variable "target_architecture" {
  type = string
}

variable "target_device" {
  type    = string
  default = "any"
}

variable "temp_dir" {
  type    = string
  default = "${env("ARTIFACT_DIR")}/.temp"
}

variable "ubuntu_release" {
  type = string
}

variable "image_dir" {
  type    = string
  default = "${env("HOME")}/.cache/images"
}
