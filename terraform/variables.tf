variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "ami_id" {
  description = "Ubuntu Server AMI ID for EU region"
  type        = string
  # Ubuntu 22.04 LTS in eu-west-1
  default     = "ami-0905a3c97561e0b69"
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "votex-deploy-key"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/votex_key.pub"
}
