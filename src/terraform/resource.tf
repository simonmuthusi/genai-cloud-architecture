resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = True
  enable_dns_hostnames = True
  tags = {
    Name = "VPC1"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    Name = "VPC Internet Gateway"
  }
}

resource "aws_vpn_gateway_attachment" "attach_gateway" {
  vpc_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.vpc.arn
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = True
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.vpc.arn
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = False
  availability_zone       = "us-east-2a"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.vpc.arn
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = True
  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.vpc.arn
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = False
  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_ec2_host" "public_route" {
  asset_id = aws_route_table.public_route_table.id
  // CF Property(DestinationCidrBlock) = "0.0.0.0/0"
  // CF Property(GatewayId) = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_subnet_route_table_association1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_route_table_association2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private_subnet_route_table_association1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_route_table_association2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_ec2_instance_state" "ec2_instance1" {
  // CF Property(ImageId) = "ami-0ccabb5f82d4c9af5"
  instance_id = "t2.micro"
  // CF Property(SecurityGroupIds) = [
  //   aws_security_group.ec2_security_group.arn
  // ]
  // CF Property(SubnetId) = aws_subnet.public_subnet1.id
  // CF Property(KeyName) = var.key_name
  // CF Property(UserData) = base64encode("#!/bin/bash
  // yum update -y
  // yum install -y httpd
  // systemctl restart httpd
  // systemctl enable httpd
  // touch /var/www/html/index.html
  // echo "<h1>Hello from Region us-east-2b</h1>" > /var/www/html/index.html
  // ")
}

resource "aws_ec2_instance_state" "ec2_instance2" {
  // CF Property(ImageId) = "ami-0ccabb5f82d4c9af5"
  instance_id = "t2.micro"
  // CF Property(SecurityGroupIds) = [
  //   aws_security_group.ec2_security_group.arn
  // ]
  // CF Property(SubnetId) = aws_subnet.public_subnet2.id
  // CF Property(KeyName) = var.key_name
  // CF Property(UserData) = base64encode("yum update -y
  // yum install -y httpd
  // systemctl restart httpd
  // systemctl enable httpd
  // touch /var/www/html/index.html
  // echo "<h1>Hello from Region us-east-2b</h1>" > /var/www/html/index.html
  // ")
}

resource "aws_security_group" "elb_security_group" {
  description = "ELB Security Group"
  vpc_id      = aws_vpc.vpc.arn
  ingress = [
    {
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_security_group" "ec2_security_group" {
  description = var.security_group_description
  vpc_id      = aws_vpc.vpc.arn
  ingress = [
    {
      protocol        = "tcp"
      from_port       = 80
      to_port         = 80
      security_groups = aws_security_group.elb_security_group.id
    },
    {
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_lb_target_group_attachment" "ec2_target_group" {
  // CF Property(HealthCheckIntervalSeconds) = 30
  // CF Property(HealthCheckProtocol) = "HTTP"
  // CF Property(HealthCheckTimeoutSeconds) = 15
  // CF Property(HealthyThresholdCount) = 5
  // CF Property(Matcher) = {
  //   HttpCode = "200"
  // }
  // CF Property(Name) = "EC2TargetGroup"
  port = 80
  // CF Property(Protocol) = "HTTP"
  target_id = aws_vpc.vpc.arn
  // CF Property(Targets) = [
  //   {
  //     Id = aws_ec2_instance_state.ec2_instance1.id
  //     Port = 80
  //   },
  //   {
  //     Id = aws_ec2_instance_state.ec2_instance2.id
  //     Port = 80
  //   }
  // ]
  // CF Property(UnhealthyThresholdCount) = 3
}

resource "aws_load_balancer_listener_policy" "alb_listener" {
  // CF Property(DefaultActions) = [
  //   {
  //     Type = "forward"
  //     TargetGroupArn = aws_lb_target_group_attachment.ec2_target_group.id
  //   }
  // ]
  load_balancer_name = aws_load_balancer_listener_policy.application_load_balancer.id
  load_balancer_port = 80
  // CF Property(Protocol) = "HTTP"
}

resource "aws_load_balancer_listener_policy" "application_load_balancer" {
  // CF Property(Scheme) = "internet-facing"
  // CF Property(Subnets) = [
  //   aws_subnet.public_subnet1.id,
  //   aws_subnet.public_subnet2.id
  // ]
  // CF Property(SecurityGroups) = [
  //   aws_security_group.elb_security_group.id
  // ]
}

