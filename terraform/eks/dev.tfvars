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

# Restrict SSH access to jump server — replace with your team's actual IP(s)
# e.g. ssh_allowed_cidrs = ["203.0.113.10/32", "198.51.100.0/24"]
ssh_allowed_cidrs = ["0.0.0.0/0"]
