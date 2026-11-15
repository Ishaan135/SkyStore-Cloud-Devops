# ---------- S3: encrypted, private bucket for user files ----------
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "files" {
  bucket = "${var.project_name}-files-${random_id.suffix.hex}"
  tags   = { Project = var.project_name }
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket                  = aws_s3_bucket.files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# Browser uploads use pre-signed PUT URLs, so CORS is required
resource "aws_s3_bucket_cors_configuration" "files" {
  bucket = aws_s3_bucket.files.id
  cors_rule {
    allowed_methods = ["GET", "PUT", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
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
      Resource = "${aws_s3_bucket.files.arn}/*"
    }]
  })
}

resource "aws_iam_access_key" "app" {
  count = var.create_iam_user ? 1 : 0
  user  = aws_iam_user.app[0].name
}

# ---------- EC2: Docker host running the app ----------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "web" {
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
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
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
