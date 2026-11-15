# ---------- S3: encrypted, private bucket for user files ----------
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.project_name}-files-${random_id.suffix.hex}"
}

# The bucket is created through a CloudFormation stack managed by Terraform.
# (AWS Academy Learner Lab's policy denies s3:GetBucketObjectLockConfiguration, which the
# aws_s3_bucket resource always calls, so the native resource cannot be used there.)
resource "aws_cloudformation_stack" "files" {
  name = "${var.project_name}-s3"
  template_body = jsonencode({
    Resources = {
      FilesBucket = {
        Type = "AWS::S3::Bucket"
        Properties = {
          BucketName = local.bucket_name
          VersioningConfiguration = { Status = "Enabled" }
          BucketEncryption = {
            ServerSideEncryptionConfiguration = [{
              ServerSideEncryptionByDefault = { SSEAlgorithm = "AES256" }
            }]
          }
          PublicAccessBlockConfiguration = {
            BlockPublicAcls       = true
            BlockPublicPolicy     = true
            IgnorePublicAcls      = true
            RestrictPublicBuckets = true
          }
          # Browser uploads use pre-signed PUT URLs, so CORS is required
          CorsConfiguration = {
            CorsRules = [{
              AllowedMethods = ["GET", "PUT", "DELETE", "HEAD"]
              AllowedOrigins = ["*"]
              AllowedHeaders = ["*"]
              ExposedHeaders = ["ETag"]
              MaxAge         = 3000
            }]
          }
          Tags = [{ Key = "Project", Value = var.project_name }]
        }
      }
    }
    Outputs = { BucketName = { Value = { Ref = "FilesBucket" } } }
  })
}

# ---------- IAM: least-privilege user used by the Convex backend ----------
resource "aws_iam_user" "app" {
  count = var.create_iam_user ? 1 : 0
  name = "${var.project_name}-convex-user"
}

resource "aws_iam_user_policy" "app" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.project_name}-s3-access"
  user  = aws_iam_user.app[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
      Resource = "arn:aws:s3:::${local.bucket_name}/*"
    }]
  })
}

resource "aws_iam_access_key" "app" {
  count = var.create_iam_user ? 1 : 0
  user  = aws_iam_user.app[0].name
}

# ---------- EC2: Docker host running the app ----------
data "aws_ami" "al2023" {
  count = var.create_ec2 ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "web" {
  count = var.create_ec2 ? 1 : 0
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  count = var.create_ec2 ? 1 : 0
  ami                    = data.aws_ami.al2023[0].id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web[0].id]
  tags                   = { Name = "${var.project_name}-app" }

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y docker git
    systemctl enable --now docker
    git clone ${var.repo_url} /opt/skystore
    cd /opt/skystore
    docker build -t skystore .
    docker run -d --restart unless-stopped -p 80:80 skystore
  EOT
}
