# -----------------------------------------------------------------------------
# Compute module outputs
# NOTE: EC2 instances are created by the Auto Scaling Group (Stage 6),
# so this module exposes only the configuration artifacts it owns.
# -----------------------------------------------------------------------------

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding application credentials"
  value       = aws_secretsmanager_secret.app_config.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_config.name
}

output "instance_profile_name" {
  description = "IAM instance profile attached to application instances"
  value       = data.aws_iam_instance_profile.app_instance.name
}

output "vpc_id" {
  description = "VPC resolved from the networking module"
  value       = data.aws_vpc.app.id
}

output "subnet_public_a_id" {
  description = "Public subnet used by the launch template"
  value       = data.aws_subnet.public_a.id
}

output "security_group_id" {
  description = "Application security group used by the launch template"
  value       = data.aws_security_group.app.id
}

output "iam_role_id" {
  description = "EC2 IAM role that grants secret read access"
  value       = data.aws_iam_role.app_instance.id
}