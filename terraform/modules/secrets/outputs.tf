output "openai_api_key_secret_name" {
  description = "Name of the OpenAI API key secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.openai_api_key.name
}

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "eso_role_arn" {
  description = "ARN of the IRSA IAM role for External Secrets Operator"
  value       = aws_iam_role.eso.arn
}

output "eso_role_name" {
  description = "Name of the IRSA IAM role for External Secrets Operator"
  value       = aws_iam_role.eso.name
}
