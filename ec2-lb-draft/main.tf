provider "aws" {
  region = "us-east-1" # specify your desired region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # specify your desired availability zone
}

# Create a security group
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id

  # Allow inbound traffic on port 80 for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic on port 22 for SSH (only for demonstration, adjust as needed)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the Application Load Balancer (ALB)
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets            = [aws_subnet.subnet.id]
}

# Create a target group
resource "aws_lb_target_group" "example_target_group" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

# Create the launch configuration for EC2 instances
resource "aws_launch_configuration" "example" {
  image_id        = "ami-12345678" # Specify your desired AMI ID
  instance_type   = "t2.micro"     # Specify your desired instance type
  security_groups = [aws_security_group.instance_sg.name]

  lifecycle {
    create_before_destroy = true
  }
}

# Create the Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  launch_configuration          = aws_launch_configuration.example.name
  min_size                      = 1
  max_size                      = 3
  desired_capacity              = 2
  vpc_zone_identifier           = [aws_subnet.subnet.id]
  target_group_arns             = [aws_lb_target_group.example_target_group.arn]
  health_check_type             = "ELB"
  health_check_grace_period     = 300
  termination_policies          = ["Default"]
}
