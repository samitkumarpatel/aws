terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41"
    }

    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }

  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "tools/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  region = "eu-north-1"

  ami           = "ami-0e2c8caa4b6378d8c"
  instance_type = "t3.small"
  vm_count      = 2
  name          = "tools"

}

provider "aws" {
  region = local.region
}

#VPC
resource "aws_vpc" "tools_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "${local.name}-vpc"
  }
}

#INTERNET GATEWAY (IGW) 
resource "aws_internet_gateway" "tools_igw" {
  vpc_id = aws_vpc.tools_vpc.id

  tags = {
    Name = "${local.name}-igw"
  }
}

#SUBNET
resource "aws_subnet" "tools_public_subnet" {
  vpc_id                  = aws_vpc.tools_vpc.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.name}-public-subnet"
  }
}

# ROUTE TABLE
resource "aws_route_table" "tools_route_table" {
  vpc_id = aws_vpc.tools_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tools_igw.id
  }
  tags = {
    Name = "${local.name}-route-table"
  }
}

# subnet attachment to ROUTE TABLE
resource "aws_route_table_association" "tools_route_table_association" {
  depends_on = [
    aws_subnet.tools_public_subnet
  ]
  subnet_id      = aws_subnet.tools_public_subnet.id
  route_table_id = aws_route_table.tools_route_table.id
}

# SECURITY GROUP
resource "aws_security_group" "tools_sg" {
  vpc_id = aws_vpc.tools_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http 8080"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg"
  }

}

# RSA KEY PAIR
resource "tls_private_key" "foo" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "foo" {
  key_name   = "id_rsa"
  public_key = tls_private_key.foo.public_key_openssh
}

output "ssh_key" {
  value     = tls_private_key.foo.private_key_pem
  sensitive = true
}

# NETWORK INTERFACES
resource "aws_network_interface" "network_interface" {
  count           = local.vm_count
  subnet_id       = aws_subnet.tools_public_subnet.id
  security_groups = [aws_security_group.tools_sg.id]
  
  tags = {
    Name = "${local.name}-ni"
  }
}

# WORKER INSTANCES
resource "aws_instance" "tools_vm" {
  count         = local.vm_count
  ami           = local.ami
  instance_type = local.instance_type
  key_name      = aws_key_pair.foo.key_name

  # Attach each worker instance to its corresponding network interface
  network_interface {
    network_interface_id = aws_network_interface.network_interface[count.index].id
    device_index         = 0
  }

  tags = {
    Name = "${local.name}-vm-${count.index + 1}"
  }
  
}

output "vm_ips" {
  value = [for instance in aws_instance.tools_vm : instance.public_ip]
}

# ansible ansible-inventory -i inventory.yml --list (show the inventory)
resource "ansible_host" "worker" {
  count = local.vm_count

  name   = aws_instance.tools_vm[count.index].public_ip
  groups = ["vm"]
  variables = {
    ansible_user                 = "ubuntu"
    ansible_ssh_private_key_file = "id_rsa.pem"
    ansible_connection           = "ssh"
    ansible_ssh_common_args      = "-o StrictHostKeyChecking=no"
    ansible_python_interpreter   = "/usr/bin/python3"
  }

}
