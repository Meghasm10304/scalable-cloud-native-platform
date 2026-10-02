variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu Server"
  type        = string
  default     = "ami-01a00762f46d584a1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "my-cine-key"
}

variable "tmdb_api_key" {
  description = "TMDB API Key"
  type        = string
  sensitive   = true
}

variable "lastfm_api_key" {
  description = "Last.fm API Key"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name used for resource naming"
  type        = string
  default     = "learning"
}