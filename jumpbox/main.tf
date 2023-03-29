#VPC
resource "aws_vpc" "foo" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "foo-example"
  }
}

resource "aws_vpc" "foo-2" {
  cidr_block = "20.0.0.0/24"
  tags = {
    Name = "foo-example"
  }
}

# PEERING
resource "aws_vpc_peering_connection" "foo" {
  #peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.foo.id
  vpc_id        = aws_vpc.foo-2.id
  auto_accept   = true

  tags = {
    Name = "foo-example"
  }
}


#INTERNET GATEWAY (IGW) 
resource "aws_internet_gateway" "foo" {
  vpc_id = aws_vpc.foo.id

  tags = {
    Name = "foo-example"
  }
}

#SUBNET
resource "aws_subnet" "foo-private" {
  vpc_id            = aws_vpc.foo.id
  cidr_block        = "10.0.0.0/25"
  tags = {
    Name = "foo-example"
  }
}

resource "aws_subnet" "foo-public" {
  vpc_id            = aws_vpc.foo.id
  cidr_block        = "10.0.0.128/25"
  map_public_ip_on_launch = true
  tags = {
    Name = "foo-example"
  }
}

resource "aws_subnet" "foo2-private" {
  vpc_id            = aws_vpc.foo-2.id
  cidr_block        = "20.0.0.0/25"
  tags = {
    Name = "foo-example"
  }
}



# ROUTE TABLE
resource "aws_route_table" "foo" {
  vpc_id = aws_vpc.foo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foo.id
  }
  route {
    cidr_block = aws_vpc.foo-2.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
  }
  tags = {
    Name = "foo-example"
  }
}

resource "aws_route_table" "foo-2" {
  vpc_id = aws_vpc.foo-2.id
  
  route {
    cidr_block = aws_vpc.foo.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
  }
  tags = {
    Name = "foo-example"
  }
}

# subnet are being attached to the route table
resource "aws_route_table_association" "foo" {
  depends_on = [
    aws_subnet.foo-public
  ]
  subnet_id      = aws_subnet.foo-public.id
  route_table_id = aws_route_table.foo.id
}
resource "aws_route_table_association" "foo1" {
  depends_on = [
    aws_subnet.foo-private
  ]
  subnet_id      = aws_subnet.foo-private.id
  route_table_id = aws_route_table.foo.id
}
resource "aws_route_table_association" "foo-2" {
  depends_on = [
    aws_subnet.foo2-private
  ]
  subnet_id      = aws_subnet.foo2-private.id
  route_table_id = aws_route_table.foo-2.id
}


#SECURITY GROUP
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "foo-example"
  }
}

resource "aws_security_group" "foo-2" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.foo-2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "foo-example"
  }
}

#NETWORK INTERFACE
resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.foo-public.id

  security_groups = [aws_security_group.foo.id]
  tags = {
    Name = "foo-example"
  }
}

resource "aws_network_interface" "foo-2" {
  subnet_id   = aws_subnet.foo2-private.id

  security_groups = [aws_security_group.foo-2.id]
  tags = {
    Name = "foo-example"
  }
}

#KEY PAIR
resource "tls_private_key" "foo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "foo" {
  key_name   = "foo-example"
  public_key = tls_private_key.foo.public_key_openssh

  provisioner "local-exec"{
    command = "echo '${tls_private_key.foo.private_key_pem}' > ./foo-example.pem"
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
    Name = "foo-example"
  }
}

resource "aws_instance" "foo-2" {
  ami = "ami-0cf72be2f86b04e9b"
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo-2.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name = aws_key_pair.foo.key_name

  tags = {
    Name = "foo-example"
  }
}
