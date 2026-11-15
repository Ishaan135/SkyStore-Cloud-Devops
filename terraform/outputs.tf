output "s3_bucket_name" { value = aws_s3_bucket.files.bucket }
output "app_public_ip" { value = aws_instance.app.public_ip }
output "app_url" { value = "http://${aws_instance.app.public_ip}" }
output "iam_access_key_id" { value = try(aws_iam_access_key.app[0].id, null) }
output "iam_secret_access_key" {
  value     = try(aws_iam_access_key.app[0].secret, null)
  sensitive = true
}
