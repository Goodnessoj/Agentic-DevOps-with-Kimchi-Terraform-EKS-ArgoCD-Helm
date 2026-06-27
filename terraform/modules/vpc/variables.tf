variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for subnet deployment"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
