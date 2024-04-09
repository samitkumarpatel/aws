#VPC
resource "aws_default_vpc" "foo" {
  tags = {
    Name = "default"
  }
}

# SUBNET
resource "aws_default_subnet" "foo-az1" {
  availability_zone = "eu-north-1a"

  tags = {
    Name = "default"
  }
}

resource "aws_internet_gateway" "foo" {
  vpc_id = aws_default_vpc.foo.id

  tags = {
    Name = "ec2-efs"
  }
}

data "aws_vpc" "selected" {
  id = aws_default_vpc.foo.id
}


resource "aws_default_route_table" "example" {
  default_route_table_id = data.aws_vpc.selected.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foo.id
  }

  tags = {
    Name = "default"
  }
}

resource "aws_route_table_association" "foo" {
  depends_on = [
    aws_default_subnet.foo-az1
  ]
  subnet_id      = aws_default_subnet.foo-az1.id
  route_table_id = aws_default_route_table.example.id
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-efs"
  }
}

#NETWORK INTERFACE
resource "aws_network_interface" "foo" {
  count     = 2
  subnet_id = aws_default_subnet.foo-az1.id

  security_groups = [aws_security_group.ec2.id]
  tags = {
    Name = "ec2-efs"
  }
}


#ssh-keygen -t rsa -b 4096 -f ./keypair/id_rsa
resource "aws_key_pair" "foo" {
  key_name   = "id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfBRCVHth6w4Iv/EtyhBB5TLEbjZ8u4arKIK9/4awPzk03G+Q3+Nq1r7di/COQe+bO9sfIG2GuLXCi1Ze1hyGP3zkpzb0vT+tW+b3fjpjUi/WSzTuxRVttiVOD9R4XAHJR0qXccN/RmwhXrmxHM9kITjACkceREgCHbo4vMA2gvnSRQS7Gxy7rWUun5WCvoHFvrnF159PQyjqPyiONY/jSVT5xXteUP4svHYfoAv0lIcPqczBLGvXnpMMAMOSC/7dLewjV0mDA8JaYwK5xvS4gHqixcjltEgSr/X/MQ7qeHfm4gaadklRCXWuhC8UCi5O/3IS595riZEhv+4slkyvq9kBUK99x4XfB1DhPB06dVNFuRVVqA6dO8EQRuC7fbR2DabYAY9lLyKdvnqRj0l70YrDTnoHURP5q5cfTZeFE+ckNRtQ3Y6aKZHU9V4gpoAK2Kuu9DRwQF3EQAoaM7W2he3z7CynnJ7NUzQF7JPxlSOg5/JRVa/O7GK7bDButy73GyS4YC+qKaUgUrVbNC6cj6Yq0DRGygLW/ho3rEpGA5Gm4ZIytI+Sn85Adjy9qumf4u4bswQEfkxU4UcAAPjgPWh/hKG8W59yABlRlj+H17SDlxuavnQV1+Rt78NK+RdPdYwfx7ekqj4lyewGdpnEdnzjY8maccJzYsvmr9tAoZQ== email@exxample.com"
}

#EC2
resource "aws_instance" "foo" {
  count         = 2
  ami           = "ami-0014ce3e52359afbd"
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo[count.index].id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name  = aws_key_pair.foo.key_name
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
  creation_token   = "efs-ec2-lb-example"
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
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # ec2-sg
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_efs_mount_target" "foo" {
  file_system_id  = aws_efs_file_system.foo.id
  subnet_id       = aws_default_subnet.foo-az1.id
  security_groups = [aws_security_group.efs.id]
}


output "ec2_host_public_ip" {
  value = aws_instance.foo[*].public_ip
}

output "efs_hostname" {
  value = aws_efs_file_system.foo.dns_name
}

locals {
  template_vars = {
    ec2_hosts            = [for ip in aws_instance.foo[*].public_ip : "${ip}"]
    efs_hostname         = aws_efs_file_system.foo.dns_name
    ssh_private_key_file = "~/ec2.pem"
  }
}

resource "local_file" "foo" {
  content  = templatefile("${path.module}/ansible/inventory.ini.tftpl", local.template_vars)
  filename = "${path.module}/ansible/inventory.ini"
}
