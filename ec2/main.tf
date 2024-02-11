#VPC
resource "aws_vpc" "foo" {
  cidr_block = "10.0.0.0/24"
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


# ROUTE TABLE
resource "aws_route_table" "foo" {
  vpc_id = aws_vpc.foo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foo.id
  }
  tags = {
    Name = "foo-example"
  }
}

# subnet attachment to ROUTE TABLE
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

  ingress {
    from_port   = 8080
    to_port     = 8080
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

#EC2
resource "aws_instance" "foo" {
  ami = "ami-0014ce3e52359afbd" 
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
