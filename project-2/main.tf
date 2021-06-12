# provider configuration

provider "aws" {
  region = "us-east-1"
  access_key = "access-key"
  secret_key = "secret-key"
}

#variables

variable "subnet_prefix" {
    description = "cidr block for the subnet"
    type        = any
}

# creating a VPC

resource "aws_vpc" "prod-vpc" {
  cidr_block       = var.subnet_prefix
  instance_tenancy = "default"

  tags = {
    Name = "prod-vpc"
  }
}

# creating an internet gateway

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-IGW"
  }
}

# creating a custom route table

resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.prod-igw.id
  }

  tags = {
    Name = "prod-RT"
  }
}

# creating a subnet and specifying an az

resource "aws_subnet" "prod-subnet" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.0.0/26"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

# associating subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-rt.id
}

# creating security group to allow port 22, 80 and 443

resource "aws_security_group" "prod-sg" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-sg"
  }
}

# creating a network interface

resource "aws_network_interface" "prod-nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.prod-sg.id]
}

# creating an elastic ip to the network interface above

resource "aws_eip" "prod-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.prod-nic.id
  associate_with_private_ip = "10.0.0.50"
  depends_on                = [
                                aws_internet_gateway.prod-igw
  ]
}

# for output when applying or refreshing

output "server_public_ip" {
    value = aws_eip.prod-eip.public_ip
}

output "server_private_ip" {
    value = aws_instance.prod-ubuntu.private_ip  
}

output "server_id" {
  value = aws_instance.prod-ubuntu.id
}

# creating an ubuntu ec2 instance and installing apache server

resource "aws_instance" "prod-ubuntu" {
  ami               = "ami-09e67e426f25ce0d7"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "access-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.prod-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first server > /var/www/html/index.html'
                EOF

  tags = {
    Name = "prod-ubuntu"
  }
}