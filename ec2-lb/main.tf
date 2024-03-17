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
  availability_zone = "eu-north-1a"
  tags = {
    Name = "foo-example"
  }
}

resource "aws_subnet" "foo-public" {
  vpc_id            = aws_vpc.foo.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = "eu-north-1b"
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
  name        = "ec2-sg"
  description = "Allow SSH and Http inbound traffic"
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
    Name = "foo-example"
  }
}

resource "aws_security_group" "foo-lb" {
  name        = "lb-sg"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.foo.id

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

  tags = {
    Name = "foo-example"
  }
}

#NETWORK INTERFACE
resource "aws_network_interface" "foo" {
  count       = 2
  subnet_id   = aws_subnet.foo-public.id

  security_groups = [aws_security_group.foo.id]
  tags = {
    Name = "foo-example"
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

  key_name   =  data.aws_key_pair.foo.key_name

  tags = {
    Name = "foo-example"
  }
}

# Load Balancer
resource "aws_lb_target_group" "foo" {
  name     = "foo-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.foo.id
  health_check {
    enabled = true
    port = 80
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "foo" {
  count = 2
  target_group_arn = aws_lb_target_group.foo.arn
  target_id        = aws_instance.foo[count.index].id
  port             = 80
}

resource "aws_lb" "foo" {
  name               = "foo-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.foo-lb.id]
  subnets            = [aws_subnet.foo-public.id, aws_subnet.foo-private.id]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "foo-example"
  }
}

resource "aws_lb_listener" "foo" {
  load_balancer_arn = aws_lb.foo.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.foo.arn
  }
}