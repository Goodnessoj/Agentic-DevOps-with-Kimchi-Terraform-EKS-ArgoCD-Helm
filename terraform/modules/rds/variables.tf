variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "eks_node_sg_id" {
  description = "Security group ID of the EKS nodes, allowed to reach MySQL"
  type        = string
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

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GiB"
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp2"
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

variable "db_deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "db_master_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "petclinic"
}

variable "tags" {
  description = "Additional tags to apply to RDS resources"
  type        = map(string)
  default     = {}
}
