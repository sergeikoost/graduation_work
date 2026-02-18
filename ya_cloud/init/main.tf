provider "yandex" {
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  token     = var.yc_token
}

resource "yandex_iam_service_account" "tf" {
  name = var.sa_name
}

# Права для этапа 1: бакет + VPC
resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.yc_folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc_admin" {
  folder_id = var.yc_folder_id
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

# S3 ключи для backend terraform
resource "yandex_iam_service_account_static_access_key" "tf_s3" {
  service_account_id = yandex_iam_service_account.tf.id
  description        = "Static access key for Terraform state in Object Storage"
}

# бакет для хранения tfstate
resource "yandex_storage_bucket" "tf_state" {
  bucket        = var.bucket_name
  force_destroy = true

  access_key = yandex_iam_service_account_static_access_key.tf_s3.access_key
  secret_key = yandex_iam_service_account_static_access_key.tf_s3.secret_key

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }
}
