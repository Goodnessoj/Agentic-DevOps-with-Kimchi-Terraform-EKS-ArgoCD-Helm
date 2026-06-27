variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (e.g., dev or prod)"
  type        = string
}

variable "service_names" {
  description = "List of microservice names to create ECR repositories for"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push for all ECR repositories"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all ECR resources"
  type        = map(string)
  default     = {}
}
