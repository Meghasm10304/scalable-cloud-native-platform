output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.app.id
}

output "subnet_public_a_id" {
  description = "Public subnet AZ-a ID"
  value       = aws_subnet.public_a.id
}

output "subnet_public_b_id" {
  description = "Public subnet AZ-b ID"
  value       = aws_subnet.public_b.id
}

output "subnet_private_a_id" {
  description = "Private subnet AZ-a ID"
  value       = aws_subnet.private_a.id
}

output "subnet_private_b_id" {
  description = "Private subnet AZ-b ID"
  value       = aws_subnet.private_b.id
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.app.id
}

output "route_table_public_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "route_table_private_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

output "sg_security_hub_id" {
  description = "Security Hub SG ID"
  value       = aws_security_group.security_hub.id
}

output "sg_web_id" {
  description = "Web SG ID"
  value       = aws_security_group.web.id
}

output "sg_app_id" {
  description = "App SG ID"
  value       = aws_security_group.app.id
}