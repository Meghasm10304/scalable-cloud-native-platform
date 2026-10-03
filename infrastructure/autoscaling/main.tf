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
# Reference existing resources by tag (same pattern as other roots)
# -----------------------------------------------------------------------------

data "aws_vpc" "app" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc"]
  }
}

data "aws_subnet" "private_a" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc-private-a"]
  }
}

data "aws_subnet" "private_b" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc-private-b"]
  }
}

data "aws_security_group" "app" {
  filter {
    name   = "tag:Name"
    values = ["app"]
  }
}

data "aws_lb_target_group" "app_tg" {
  name = "${var.environment}-app-tg"
}

data "aws_iam_instance_profile" "app_instance" {
  name = "${var.environment}-app-instance-profile"
}

# Latest Ubuntu 22.04 LTS AMI in ap-south-1
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Launch Template — the blueprint for every instance the ASG creates
# -----------------------------------------------------------------------------

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-cinesangeet-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [data.aws_security_group.app.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.app_instance.name
  }

  key_name = var.key_name

  user_data = base64encode(file("${path.module}/bootstrap.sh"))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2 (security best practice)
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.environment}-cinesangeet-asg"
      Stage   = "6"
      Project = "cloud-native-platform"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name    = "${var.environment}-cinesangeet-volume"
      Project = "cloud-native-platform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.environment}-cinesangeet-lt"
    Stage   = "6"
    Project = "cloud-native-platform"
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group — keeps N instances running across both AZs
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "app" {
  name                      = "${var.environment}-cinesangeet-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = [data.aws_subnet.private_a.id, data.aws_subnet.private_b.id]
  target_group_arns         = [data.aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = false

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-cinesangeet-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Stage"
    value               = "6"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "cloud-native-platform"
    propagate_at_launch = true
  }
}

# -----------------------------------------------------------------------------
# Scaling Policies — CPU-based scale out/in
# -----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.environment}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.environment}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 30.0
  }
}