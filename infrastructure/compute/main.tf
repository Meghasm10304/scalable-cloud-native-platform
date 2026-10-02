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

data "aws_security_group" "web" {
  filter {
    name   = "tag:Name"
    values = ["web"]
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance — Stage 4
# -----------------------------------------------------------------------------

resource "aws_instance" "cinesangeet_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.public_a.id
  vpc_security_group_ids = [data.aws_security_group.web.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  # This is the output you'll use for SSH
  tags = {
    Name    = "cinesangeet-server"
    Stage   = "4"
    Project = "cloud-native-platform"
  }
}