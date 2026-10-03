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
# Reference existing networking resources by tag (same pattern as compute)
# -----------------------------------------------------------------------------

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

data "aws_subnet" "public_b" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc-public-b"]
  }
}

data "aws_security_group" "web" {
  filter {
    name   = "tag:Name"
    values = ["web"]
  }
}

# Look up the EC2 instance created by the compute root (do NOT recreate it)
data "aws_instance" "app_server" {
  filter {
    name   = "tag:Name"
    values = ["cinesangeet-server"]
  }
}

# -----------------------------------------------------------------------------
# Application Load Balancer — Stage 5
# -----------------------------------------------------------------------------

resource "aws_lb" "app_alb" {
  name               = "${var.environment}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.web.id]
  subnets            = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name    = "${var.environment}-app-alb"
    Stage   = "5"
    Project = "cloud-native-platform"
  }
}

# -----------------------------------------------------------------------------
# Target Group — backend pool pointing at the EC2 on port 3000
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.environment}-app-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.app.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "${var.environment}-app-tg"
    Stage   = "5"
    Project = "cloud-native-platform"
  }
}

# -----------------------------------------------------------------------------
# Register the EXISTING EC2 with the target group
# (cross-root reference via data source — no state coupling)
# -----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "app_ec2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = data.aws_instance.app_server.id
  port             = 3000
}

# -----------------------------------------------------------------------------
# HTTP Listener
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}