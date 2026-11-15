output "s3_bucket_name" { value = aws_s3_bucket.files.bucket }
output "app_public_ip" { value = aws_instance.app.public_ip }
output "app_url" { value = "http://${aws_instance.app.public_ip}" }
output "iam_access_key_id" { value = aws_iam_access_key.app.id }
output "iam_secret_access_key" {
  value     = aws_iam_access_key.app.secret
  sensitive = true
}
