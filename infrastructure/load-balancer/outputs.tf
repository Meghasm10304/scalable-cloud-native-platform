output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID (for DNS records)"
  value       = aws_lb.app_alb.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance being registered"
  value       = data.aws_instance.app_server.private_ip
}