provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  token     = var.yc_token
}

resource "yandex_iam_service_account" "tf" {
  name = var.sa_name
}


resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc_admin" {
  folder_id = var.folder_id
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

# Статический ключ для S3
resource "yandex_iam_service_account_static_access_key" "tf_s3" {
  service_account_id = yandex_iam_service_account.tf.id
  description        = "Static access key for Terraform state in Object Storage"
}

# Bucket для хранения tfstate
resource "yandex_storage_bucket" "tf_state" {
  bucket        = var.bucket_name
  force_destroy = true

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }
}
