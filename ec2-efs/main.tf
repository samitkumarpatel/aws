#VPC
resource "aws_default_vpc" "foo" {
  tags = {
    Name = "ec2-efs"
  }
}

# SUBNET
resource "aws_default_subnet" "foo-az1" {
  availability_zone = "eu-north-1a"

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_internet_gateway" "foo" {
  vpc_id = aws_default_vpc.foo.id

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_route_table" "foo" {
  vpc_id = aws_default_vpc.foo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foo.id
  }
  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_route_table_association" "foo" {
  depends_on = [
    aws_default_subnet.foo-az1
  ]
  subnet_id      = aws_default_subnet.foo-az1.id
  route_table_id = aws_route_table.foo.id
}


#SECURITY GROUP
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow SSH and Http inbound traffic"
  vpc_id      = aws_default_vpc.foo.id

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
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-efs"
  }
}

#NETWORK INTERFACE
resource "aws_network_interface" "foo" {
  count       = 2
  subnet_id   = aws_default_subnet.foo-az1.id

  security_groups = [aws_security_group.ec2.id]
  tags = {
    Name = "ec2-efs"
  }
}


data "aws_key_pair" "foo" {
  key_name           = "lenovo"
  include_public_key = true
}

#EC2
resource "aws_instance" "foo" {
  count         = 2
  ami           = "ami-0014ce3e52359afbd" 
  instance_type = "t3.micro"

  network_interface {
    network_interface_id  = aws_network_interface.foo[count.index].id
    device_index          = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name  =  data.aws_key_pair.foo.key_name
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              apt-get install nfs-common -y
              EOF 

  tags = {
    Name = "ec2-efs"
  }
}

# EFS
resource "aws_efs_file_system" "foo" {
  creation_token  = "efs-ec2-lb-example"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow ec2-sg will talk to this efs"
  vpc_id      = aws_default_vpc.foo.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # ec2-sg
    security_groups = [ aws_security_group.ec2.id ]
  }

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_efs_mount_target" "foo" {
  file_system_id  = aws_efs_file_system.foo.id
  subnet_id       = aws_default_subnet.foo-az1.id
  security_groups = [ aws_security_group.efs.id ]
}