provider "aws" {
  region = var.aws_region
}


module "vpc" {
  source = "../modules/vpc"

  cluster_name    = var.cluster_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  aws_region      = var.aws_region
}

module "eks" {
  source = "../modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.node_instance_type
  desired_capacity   = var.desired_capacity
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

module "iam" {
  source = "../modules/iam"

  cluster_name = var.cluster_name
}

module "jump_server" {
  source = "../modules/jump-server"

  cluster_name      = var.cluster_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  aws_region        = var.aws_region
  ssh_allowed_cidrs = var.ssh_allowed_cidrs

  depends_on = [module.eks]
}

# SG rule (jump -> EKS API :443) is managed via workflow script
# to avoid duplicate-rule errors when the rule was pre-created manually.

