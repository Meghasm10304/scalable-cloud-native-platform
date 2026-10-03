# Read existing resources created by earlier stages (no cross-state dependency)
data "aws_lb" "app" {
  name = var.alb_name
}

data "aws_autoscaling_group" "app" {
  name = var.asg_name
}

data "aws_lb_target_group" "app" {
  name = var.tg_name
}

# Alarm 1: CPU too high across ASG instances
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.asg_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggered when EC2 average CPU exceeds 70% over 10 minutes"

  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_group.app.name
  }

  tags = {
    Environment = var.environment
    Project     = "cloud-native-platform"
    Stage       = "7"
  }
}

# Alarm 2: Any unhealthy target detected
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.asg_name}-unhealthy-targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Triggered when any ALB target becomes unhealthy"

    dimensions = {
      LoadBalancer = data.aws_lb.app.arn_suffix
      TargetGroup  = data.aws_lb_target_group.app.arn_suffix
    }

  tags = {
    Environment = var.environment
    Project     = "cloud-native-platform"
    Stage       = "7"
  }
}

# Dashboard: one pane showing all key metrics
resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${var.asg_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization (%)"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", data.aws_lb.app.arn_suffix, "TargetGroup", data.aws_lb_target_group.app.arn_suffix]]
          period = 60
          stat   = "Maximum"
          region = var.aws_region
          title  = "ALB Unhealthy Host Count"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", data.aws_lb.app.arn_suffix]]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Request Count"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount",
             "LoadBalancer", data.aws_lb.app.arn_suffix,
             "TargetGroup",  data.aws_lb_target_group.app.arn_suffix]
          ]
          period = 60
          stat   = "Maximum"
          region = var.aws_region
          title  = "ALB Healthy Host Count"
        }
      }
    ]
  })
}