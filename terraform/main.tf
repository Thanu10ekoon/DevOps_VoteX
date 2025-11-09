terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Security Group
resource "aws_security_group" "votex_sg" {
  name        = "votex-security-group"
  description = "Security group for VoteX application"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # Frontend
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Frontend access"
  }

  # Backend API
  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend API access"
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "votex-sg"
    Project = "VoteX"
  }
}

# Key Pair
resource "aws_key_pair" "votex_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "votex-key"
    Project = "VoteX"
  }
}

# EC2 Instance
resource "aws_instance" "votex_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.votex_key.key_name
  
  vpc_security_group_ids = [aws_security_group.votex_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              
              # Install Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io
              systemctl start docker
              systemctl enable docker
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Add ubuntu user to docker group
              usermod -aG docker ubuntu
              
              # Create app directory
              mkdir -p /home/ubuntu/votex
              chown ubuntu:ubuntu /home/ubuntu/votex
              EOF

  tags = {
    Name = "votex-server"
    Project = "VoteX"
    Environment = "production"
  }
}

# Elastic IP
resource "aws_eip" "votex_eip" {
  instance = aws_instance.votex_server.id
  domain   = "vpc"

  tags = {
    Name = "votex-eip"
    Project = "VoteX"
  }
}
