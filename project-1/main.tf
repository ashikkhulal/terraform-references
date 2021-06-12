provider "aws" {
  region = "us-east-1"
  access_key = "access-key"
  secret_key = "secret-key"
}

resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/26"
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my-subnet-1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/27"

  tags = {
    Name = "my-subnet-1"
  }
}

resource "aws_subnet" "my-subnet-2" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.32/27"

  tags = {
    Name = "my-subnet-2"
  }
}