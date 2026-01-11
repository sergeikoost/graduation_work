variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

# Файл ключа сервисного аккаунта 
variable "sa_key_file" {
  type        = string
  description = "Path to service account key JSON file"
}

variable "network_name" {
  type    = string
  default = "net-main"
}
