data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

locals {
  cluster_name    = "${var.project}-${var.environment}"
  node_group_name = "${var.project}-${var.environment}-nodes"
  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  tags = merge(local.default_tags, var.tags)
}

# Cluster IAM role
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS cluster
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  bootstrap_self_managed_addons = false

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  vpc_config {
    subnet_ids             = var.subnet_ids
    security_group_ids     = [var.cluster_sg_id]
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]

  tags = local.tags
}

# OIDC provider for IRSA
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = local.tags
}

# Node IAM role
resource "aws_iam_role" "node" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# Managed node group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  tags = local.tags
}

# Access entry for deploying principal
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}

# Core EKS managed add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]

  tags = local.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.tags
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.tags
}
