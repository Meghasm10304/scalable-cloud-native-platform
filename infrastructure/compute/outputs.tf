output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cinesangeet_server.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.cinesangeet_server.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.cinesangeet_server.private_ip
}