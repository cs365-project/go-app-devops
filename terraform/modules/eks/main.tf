# Use pre-existing LabEksClusterRole (Learner Lab restriction: cannot create IAM roles)
# Role names in Learner Lab have a generated prefix, so we look them up by path/tag filter
data "aws_iam_roles" "cluster" {
  name_regex = ".*LabEksClusterRole.*"
}

data "aws_iam_roles" "nodes" {
  name_regex = ".*LabEksNodeRole.*"
}

data "aws_iam_role" "cluster" {
  name = tolist(data.aws_iam_roles.cluster.names)[0]
}

data "aws_iam_role" "nodes" {
  name = tolist(data.aws_iam_roles.nodes.names)[0]
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = data.aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = data.aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.cluster_name}-nodes"
  }
}

# OIDC Provider removed — Learner Lab does not allow iam:CreateOpenIDConnectProvider
