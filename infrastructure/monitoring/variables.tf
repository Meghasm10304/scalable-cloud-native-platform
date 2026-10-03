variable "asg_name" {
  description = "Name of the existing Auto Scaling Group"
  type        = string
}

variable "alb_name" {
  description = "Name of the existing Application Load Balancer"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "learning"
}

variable "tg_name" {
  description = "Name of the existing ALB target group"
  type        = string
}