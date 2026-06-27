variable "region" {
  description = "AWS region for the environment"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the public subnets"
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_ami_type" {
  description = "AMI type for the EKS managed node group"
  type        = string
  default     = "AL2_ARM_64"
}

variable "node_capacity_type" {
  description = "Capacity type for the EKS managed node group"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_min_size" {
  description = "Minimum number of nodes in the EKS managed node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the EKS managed node group"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS managed node group"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Disk size in GiB for EKS managed node group instances"
  type        = number
  default     = 20
}

variable "service_names" {
  description = "List of microservice names to create ECR repositories for"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final snapshot on deletion"
  type        = bool
  default     = true
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_storage_encrypted" {
  description = "Whether to encrypt the RDS storage"
  type        = bool
  default     = true
}

