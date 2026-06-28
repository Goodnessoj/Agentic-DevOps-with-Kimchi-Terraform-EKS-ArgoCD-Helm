variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user that owns the application repo"
  type        = string
  default     = "Goodnessoj"
}

variable "github_repo" {
  description = "Name of the GitHub application repository"
  type        = string
  default     = "spring-petclinic-microservices"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the OIDC role"
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
