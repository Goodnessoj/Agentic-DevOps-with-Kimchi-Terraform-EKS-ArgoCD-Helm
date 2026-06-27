output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS credentials"
  value       = aws_secretsmanager_secret.rds_credentials.arn
  sensitive   = true
}

output "secret_name" {
  description = "Name of the Secrets Manager secret containing RDS credentials"
  value       = aws_secretsmanager_secret.rds_credentials.name
}
