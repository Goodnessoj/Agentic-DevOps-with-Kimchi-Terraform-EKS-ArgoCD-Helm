locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  db_identifier = "${var.project}-${var.environment}-mysql"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-db-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-mysql8-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = local.common_tags
}

resource "random_password" "master" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project}/${var.environment}/rds-credentials"
  description             = "RDS master credentials for ${local.db_identifier}"
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.master.result
  })
}

resource "aws_db_instance" "this" {
  identifier = local.db_identifier

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = var.db_storage_encrypted

  db_name  = "petclinic"
  username = var.db_master_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az = var.db_multi_az

  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = var.db_skip_final_snapshot
  deletion_protection     = var.db_deletion_protection

  publicly_accessible = false

  tags = merge(
    local.common_tags,
    {
      Name = local.db_identifier
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_to_mysql" {
  security_group_id = var.rds_sg_id

  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.eks_node_sg_id

  description = "MySQL access from EKS nodes"

  tags = local.common_tags
}
