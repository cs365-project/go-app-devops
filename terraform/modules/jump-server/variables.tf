variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to place the jump server in"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the jump server"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH into the jump server"
  type        = list(string)
  # Override in dev.tfvars — do not leave as 0.0.0.0/0 in production
  default = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "vockey"
}

variable "instance_profile" {
  description = "IAM instance profile for the jump server"
  type        = string
  default     = "LabInstanceProfile"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
