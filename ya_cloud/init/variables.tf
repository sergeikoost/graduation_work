variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}


variable "yc_token" {
  type      = string
  sensitive = true
}

variable "sa_name" {
  type    = string
  default = "sa-terraform"
}

variable "bucket_name" {
  type = string
}
