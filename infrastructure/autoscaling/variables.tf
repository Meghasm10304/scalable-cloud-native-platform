variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}

variable "instance_type" {
  description = "EC2 instance type for ASG"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name (for fallback access; SSM is primary)"
  type        = string
  default     = "my-cine-key"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances at steady state"
  type        = number
  default     = 1
}