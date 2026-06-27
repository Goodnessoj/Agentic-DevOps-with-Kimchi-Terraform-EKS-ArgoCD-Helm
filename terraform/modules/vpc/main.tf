locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-vpc"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name                                                      = "${var.project}-${var.environment}-public-${count.index + 1}"
      "kubernetes.io/cluster/${var.project}-${var.environment}" = "shared"
      "kubernetes.io/role/elb"                                  = "1"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-public-rt"
    }
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-eks-cluster-sg"
    }
  )
}

resource "aws_security_group" "eks_node" {
  name        = "${var.project}-${var.environment}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-eks-node-sg"
    }
  )
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-rds-sg"
    }
  )
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-alb-sg"
    }
  )
}
