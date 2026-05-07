variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-0c1e21d82fe9c9336"
}

variable "key_name" {
  type    = string
  default = "vockey"
}

variable "instance_profile" {
  type    = string
  default = "LabInstanceProfile"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
