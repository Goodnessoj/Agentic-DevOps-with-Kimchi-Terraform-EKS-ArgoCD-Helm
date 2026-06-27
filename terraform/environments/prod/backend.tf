terraform {
  backend "s3" {
    bucket       = "petclinic-terraform-state-271369142928-us-east-2"
    key          = "petclinic/prod/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
