locals {
  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  tags = merge(local.default_tags, var.tags)

  github_token_url = "token.actions.githubusercontent.com"
}

# GitHub Actions OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://${local.github_token_url}"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4e98bab03faadb97b34396831e3780aea1"] # GitHub Actions OIDC thumbprint (2024)

  tags = local.tags
}

# IAM role for GitHub Actions with OIDC trust policy
resource "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.github_token_url}:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "${local.github_token_url}:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# IAM policy allowing ECR push to both dev and prod repositories
resource "aws_iam_role_policy" "ecr_push" {
  name = "${var.project}-github-actions-ecr-push-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "PushImagesToPetclinicRepositories"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          "arn:aws:ecr:*:*:repository/${var.project}-dev/*",
          "arn:aws:ecr:*:*:repository/${var.project}-prod/*"
        ]
      }
    ]
  })
}
