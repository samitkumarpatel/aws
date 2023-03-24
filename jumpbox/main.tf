terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
  #access_key = "my-access-key" 
  #export AWS_ACCESS_KEY_ID="anaccesskey"
  #secret_key = "my-secret-key" 
  #export AWS_SECRET_ACCESS_KEY="asecretkey"
}

#VPC
resource "aws_vpc" "foo" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "tf-example"
  }
}

#SUBNET
resource "aws_subnet" "foo" {
  vpc_id            = aws_vpc.foo.id
  cidr_block        = "172.16.10.0/24"
  #availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-example"
  }
}

resource "aws_security_group" "foo" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.foo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-example"
  }
}

#NETWORK INTERFACE
resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.foo.id
  private_ips = ["172.16.10.100"]
  security_groups = [aws_security_group.foo.id]
  tags = {
    Name = "tf-example"
  }
}

#EC2
resource "aws_instance" "foo" {
  ami = "ami-0cf72be2f86b04e9b"
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name = "tf-example"
  }
}