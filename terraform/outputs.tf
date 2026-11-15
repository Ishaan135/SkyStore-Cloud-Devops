output "s3_bucket_name" { value = aws_cloudformation_stack.files.outputs["BucketName"] }
output "app_public_ip" { value = try(aws_instance.app[0].public_ip, null) }
output "app_url" { value = var.create_ec2 ? "http://${aws_instance.app[0].public_ip}" : null }
output "iam_access_key_id" { value = try(aws_iam_access_key.app[0].id, null) }
output "iam_secret_access_key" {
  value     = try(aws_iam_access_key.app[0].secret, null)
  sensitive = true
}
