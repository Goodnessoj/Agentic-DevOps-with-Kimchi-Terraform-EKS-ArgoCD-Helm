module "vpc" {
  source = "../../modules/vpc"

  project             = "petclinic"
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "eks" {
  source = "../../modules/eks"

  project             = "petclinic"
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  cluster_sg_id       = module.vpc.eks_cluster_sg_id
  node_sg_id          = module.vpc.eks_node_sg_id
  cluster_version     = var.cluster_version
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  node_disk_size      = var.node_disk_size
}

module "ecr" {
  source = "../../modules/ecr"

  project              = "petclinic"
  environment          = var.environment
  service_names        = var.service_names
  image_tag_mutability = var.environment == "prod" ? "IMMUTABLE" : "MUTABLE"
}

module "rds" {
  source = "../../modules/rds"

  project     = "petclinic"
  environment = var.environment

  subnet_ids     = module.vpc.public_subnet_ids
  rds_sg_id      = module.vpc.rds_sg_id
  eks_node_sg_id = module.vpc.eks_node_sg_id

  db_instance_class          = var.db_instance_class
  db_engine_version          = var.db_engine_version
  db_allocated_storage       = var.db_allocated_storage
  db_backup_retention_period = var.db_backup_retention_period
  db_skip_final_snapshot     = var.db_skip_final_snapshot
  db_multi_az                = var.db_multi_az
  db_storage_encrypted       = var.db_storage_encrypted

  tags = {}
}

module "secrets" {
  source = "../../modules/secrets"

  environment       = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}
