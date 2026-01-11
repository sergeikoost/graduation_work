output "service_account_id" {
  value = yandex_iam_service_account.tf.id
}

output "bucket_name" {
  value = yandex_storage_bucket.tf_state.bucket
}

output "s3_access_key" {
  value     = yandex_iam_service_account_static_access_key.tf_s3.access_key
  sensitive = true
}

output "s3_secret_key" {
  value     = yandex_iam_service_account_static_access_key.tf_s3.secret_key
  sensitive = true
}
