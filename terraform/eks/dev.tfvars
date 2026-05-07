aws_region         = "us-east-1"
cluster_name       = "cs365-eks-cluster"
cluster_version    = "1.33"
vpc_cidr           = "10.0.0.0/16"
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
node_instance_type = "t3.medium"
desired_capacity   = 2
min_capacity       = 1
max_capacity       = 3

is_eks_role_enabled          = true
is_eks_nodegroup_role_enabled = true
