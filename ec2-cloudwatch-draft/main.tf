# Create a VPC
resource "aws_vpc" "foo" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ec2-cloudwatch"
  }
}

#Internet Gateway 
resource "aws_internet_gateway" "foo" {
  vpc_id = aws_vpc.foo.id

  tags = {
    Name = "ec2-cloudwatch"
  }
}

#Route table
resource "aws_route_table" "foo" {
  vpc_id = aws_vpc.foo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foo.id
  }
  tags = {
    Name = "ec2-cloudwatch"
  }
}

# Create a subnet
resource "aws_subnet" "foo" {
  vpc_id            = aws_vpc.foo.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ec2-cloudwatch"
  }
}

# subnet attachment to ROUTE TABLE
resource "aws_route_table_association" "foo" {
  depends_on = [
    aws_subnet.foo
  ]
  subnet_id      = aws_subnet.foo.id
  route_table_id = aws_route_table.foo.id
  
}

# Create a security group
resource "aws_security_group" "foo" {
  vpc_id = aws_vpc.foo.id

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

  tags = {
    Name = "ec2-cloudwatch"
  }
}

# Create an EC2 instance
resource "aws_instance" "example" {
  ami             = "ami-087c4d241dd19276d"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.foo.id
  vpc_security_group_ids = [aws_security_group.foo.id]
  
  tags = {
    Name = "ec2-cloudwatch"
  }

  # Add CloudWatch monitoring
  monitoring = true
  
  iam_instance_profile="CloudWatchAgentServerRole"

  # Example user data for setting up a basic web server (you can modify as needed)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-cloudwatch-agent

              # Configure CloudWatch agent
              cat <<-EOF_CONFIG > /home/ec2-user/cloudwatch-config.json
              {
                "agent": {
                        "metrics_collection_interval": 60,
                        "run_as_user": "root"
                },
                "logs": {
                    "logs_collected": {
                        "files": {
                            "collect_list": [
                                    {
                                        "file_path": "/home/ec2-user/application/hello-world.log",
                                        "log_group_class": "STANDARD",
                                        "log_group_name": "application",
                                        "log_stream_name": "{instance_id}",
                                        "retention_in_days": 1
                                    }
                            ]
                        }
                    }
                },
                "metrics": {
                    "aggregation_dimensions": [
                        [
                            "InstanceId"
                        ]
                    ],
                    "append_dimensions": {
                        "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
                        "ImageId": "$${aws:ImageId}",
                        "InstanceId": "$${aws:InstanceId}",
                        "InstanceType": "$${aws:InstanceType}"
                    },
                    "metrics_collected": {
                        "disk": {
                                "measurement": [
                                        "used_percent"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "mem": {
                                "measurement": [
                                        "mem_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        },
                        "statsd": {
                                "metrics_aggregation_interval": 60,
                                "metrics_collection_interval": 10,
                                "service_address": ":8125"
                        }
                    }
                }
            }
              EOF_CONFIG

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/home/ec2-user/cloudwatch-config.json -s
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start
              EOF
}