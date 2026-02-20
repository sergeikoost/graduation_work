variable "yc_cloud_id"  { type = string }
variable "yc_folder_id" { type = string }
variable "yc_token" {
  type      = string
  sensitive = true
}

variable "network_id" { type = string }
variable "subnet_ids" {
  type = map(string)
}

variable "cluster_name" {
  type    = string
  default = "diploma-k8s"
}

variable "k8s_version" {
  type    = string
  default = "1.29"
}