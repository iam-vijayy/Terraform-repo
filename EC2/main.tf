terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.12.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Get Ubuntu 22.04 AMI
data "aws_ami" "test-ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Key Pair (reads your local public key)
resource "aws_key_pair" "test-key" {
  key_name   = "test-key"
  public_key = file("/home/vijay/.ssh/id_ed25519.pub")
}

# Security Group
resource "aws_security_group" "test-sg" {
  name        = "test-sg"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-sg"
  }
}

# EC2 Instance
resource "aws_instance" "test" {
  ami                    = data.aws_ami.test-ami.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.test-key.key_name
  vpc_security_group_ids = [aws_security_group.test-sg.id]

# Root volume (default EBS)
  root_block_device {
    volume_size = 8     # in GiB
    volume_type = "gp3"
  }

# # Extra EBS volume
#   ebs_block_device {
#     device_name           = "/dev/sdf"  # device name inside EC2
#     volume_size           = 20          # size in GiB
#     volume_type           = "gp3"
#     delete_on_termination = true
#   }

  tags = {
    Name = "test"
  }
}