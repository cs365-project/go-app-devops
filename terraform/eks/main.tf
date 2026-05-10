provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
  }
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

# Allow jump server to reach EKS API server (port 443)
# Defined here at root level to avoid circular dependency between eks and jump_server modules
resource "aws_security_group_rule" "jump_to_eks_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.jump_server.security_group_id
  security_group_id        = module.eks.cluster_security_group_id
  description              = "Allow jump server to access EKS API"

  depends_on = [module.eks, module.jump_server]
}

# Patch aws-auth configmap to grant LabRole (EC2 instance profile) cluster-admin access
# This allows kubectl to work from the jump server without manual intervention
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = data.aws_iam_role.lab_role.arn
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }

  # force = true allows merging with existing entries (node role added by EKS automatically)
  force = true

  depends_on = [module.eks]
}
