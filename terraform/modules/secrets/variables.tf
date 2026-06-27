variable "project" {
  description = "Project name used as a prefix for resource naming"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS module"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS module (used in trust policy condition)"
  type        = string
}

variable "service_account_namespace" {
  description = "Kubernetes namespace of the External Secrets Operator service account"
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "Name of the External Secrets Operator service account"
  type        = string
  default     = "external-secrets-sa"
}
