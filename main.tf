provider "aws" {
    region = "eu-north-1"
}

variable "cidr_block" {
  description = "This is list of object variable which holds all cidr_block values"
  type = list(object({
    cidr_block = string
    name = string
  }))  
}

resource "aws_vpc" "festine-tf-vpc" {
  cidr_block = var.cidr_block[0].cidr_block

  tags = {
    "Name" = var.cidr_block[0].name
  }
}

resource "aws_subnet" "tf-pubsub1" {
  cidr_block = var.cidr_block[1].cidr_block
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.festine-tf-vpc.id
  availability_zone = "eu-north-1b"

  tags = {
    "Name" = var.cidr_block[1].name
  }
}

resource "aws_internet_gateway" "tf-IG" {
  vpc_id = aws_vpc.festine-tf-vpc.id

  tags = {
    "Name" = "tf-IG"
  }
}

resource "aws_route_table" "tf-route-table" {
  vpc_id = aws_vpc.festine-tf-vpc.id

  tags = {
    Name = "tf-RT"
  }

  route {
    cidr_block = var.cidr_block[2].cidr_block
    gateway_id = aws_internet_gateway.tf-IG.id
  }
}

resource "aws_route_table_association" "subnet" {
  subnet_id = aws_subnet.tf-pubsub1.id
  route_table_id = aws_route_table.tf-route-table.id
}



