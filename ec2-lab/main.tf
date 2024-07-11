locals {
  region         = "eu-north-1"
  instance_count = 3
  tags = {
    infra = "playground"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "ec2-lab/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

# default
# VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SECURITY GROUP
resource "aws_security_group" "custom" {
  name   = "custom-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #   dynamic "ingress" {
  #     for_each = [22, 80]
  #     content {
  #       from_port = each.key
  #       to_port = ""
  #       protocol = ""
  #       cidr_blocks = ""
  #     }
  #   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_network_interface" "custom" {
  count = local.instance_count

  subnet_id       = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.custom.id]

  tags = local.tags
}

#ssh-keygen -t rsa -b 4096 -f ./keypair/id_rsa
resource "tls_private_key" "custom" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "custom" {
  key_name   = "id_rsa"
  public_key = tls_private_key.custom.public_key_openssh
}

#EC2
resource "aws_instance" "custom" {
  depends_on = [aws_network_interface.custom]
  
  count      = local.instance_count

  ami           = "ami-0014ce3e52359afbd"
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.custom[count.index].id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name = aws_key_pair.custom.key_name
  tags     = merge(local.tags, { Name = "lab" })
}

output "ssh_key" {
  value     = tls_private_key.custom.private_key_pem
  sensitive = true
}

output "ec2_ips" {
  value = [for instance in aws_instance.custom : instance.public_ip]
}
