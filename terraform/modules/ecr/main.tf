locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_ecr_repository" "service" {
  for_each = toset(var.service_names)

  name                 = "${var.project}-${var.environment}/${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each = toset(var.service_names)

  repository = aws_ecr_repository.service[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 10
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 20
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
