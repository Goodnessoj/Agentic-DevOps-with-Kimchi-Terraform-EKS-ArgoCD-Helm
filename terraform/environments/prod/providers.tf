provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "petclinic"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
