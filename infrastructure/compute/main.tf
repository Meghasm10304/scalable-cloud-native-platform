#compute
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# Reference the networking module outputs (no hardcoded IDs)
# -----------------------------------------------------------------------------
# Since your networking is in a sibling folder, we use data sources
# to read the existing state.
#
# Option A: Use data sources to read by name tags (cleaner for learning)
# Option B: Use terraform_remote_state (better for team projects)
#
# For now, Option A is simplest. If you prefer Option B, let me know.

data "aws_vpc" "app" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc"]
  }
}

data "aws_subnet" "public_a" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc-public-a"]
  }
}

data "aws_security_group" "app" {
  filter {
    name   = "tag:Name"
    values = ["app"]
  }
}

# -----------------------------------------------------------------------------
# Secret for Application Credentials
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "app_config" {
  name        = "cinesangeet/app-config-v2"
  description = "Application secrets for CineSangeet"

  tags = {
    Name    = "cinesangeet-app-config"
    Project = "cloud-native-platform"
  }
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id     = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    TMDB_API_KEY = var.tmdb_api_key
    LASTFM_KEY   = var.lastfm_api_key
  })
}

# -----------------------------------------------------------------------------
# Look up the EC2 role created in Stage 3 (networking/iam.tf) by name
# -----------------------------------------------------------------------------
data "aws_iam_role" "app_instance" {
  name = "${var.environment}-app-ec2-role"
}

# -----------------------------------------------------------------------------
# IAM Policy to Allow EC2 to Read the Secret
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "app_instance_secrets" {
  name = "app-instance-read-secrets"
  role = data.aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.app_config.arn
      }
    ]
  })
}

data "aws_iam_instance_profile" "app_instance" {
  name = "${var.environment}-app-instance-profile"
}