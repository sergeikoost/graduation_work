variable "yc_cloud_id" {
  type = string
}

variable "yc_folder_id" {
  type = string
}

variable "yc_token" {
  type      = string
  sensitive = true
}

variable "network_name" {
  type    = string
  default = "net-main"
}
