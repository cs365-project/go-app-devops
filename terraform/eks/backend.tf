terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket         = "cs365-tf-state-bucket"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cs365-tf-lock"
    encrypt        = true
  }
}
