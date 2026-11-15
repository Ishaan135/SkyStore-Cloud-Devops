variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "skystore"
}

variable "instance_type" {
  description = "EC2 instance type for the app host"
  type        = string
  default     = "t3.micro"
}

variable "repo_url" {
  description = "Git repo the EC2 host pulls and runs with docker compose"
  type        = string
  default     = "https://github.com/Ishaan135/SkyStore-Cloud-Devops.git"
}

variable "create_iam_user" {
  description = "Create a dedicated IAM user. Set false on AWS Academy Learner Lab (IAM user creation is blocked)."
  type        = bool
  default     = true
}

variable "create_ec2" {
  description = "Also create the EC2 Docker host (costs a few cents per hour)"
  type        = bool
  default     = false
}
