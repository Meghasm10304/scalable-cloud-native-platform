output "cpu_alarm_arn" {
  description = "ARN of the CPU alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "unhealthy_alarm_arn" {
  description = "ARN of the unhealthy targets alarm"
  value       = aws_cloudwatch_metric_alarm.unhealthy_targets.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.app.dashboard_name
}