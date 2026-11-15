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
  default     = "https://github.com/Samaksh912/SkyStore.git"
}
