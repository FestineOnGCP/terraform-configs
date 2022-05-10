
variable "cidr_block" {
  description = "This is list of object variable which holds all cidr_block values"
  type = list(object({
    cidr_block = string
    name = string
  }))  
}
variable "ec2_public_key" {}

resource "aws_vpc" "festine-tf-vpc" {
  cidr_block = var.cidr_block[0].cidr_block

  tags = {
    "Name" = var.cidr_block[0].name
  }
}

resource "aws_subnet" "tf-pubsub" {
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
  subnet_id = aws_subnet.tf-pubsub.id
  route_table_id = aws_route_table.tf-route-table.id
}

resource "aws_security_group" "festine-tf-SG" {
  name = "festine-tf-SG"
  description = "Security group for VMs created by Terraform"
  vpc_id = aws_vpc.festine-tf-vpc.id

  ingress {
    description = "Allow HTTPS connection from everywhere"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP connection from everywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ssh connection from my base machine"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #this will only accept ssh from my base machine
  }

  egress {
    description = "Allow connection from everywhere"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "festine-tf-SG"  
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "festine-tf-key-pair" {
  key_name = "festine-tf-key-pair"
  public_key = var.ec2_public_key
}

output "aws_ami_id" {
  value = data.aws_ami.ubuntu.id
}

resource "aws_instance" "festine-tf-ec2" {
  instance_type = "t3.micro"
  ami = data.aws_ami.ubuntu.id
  subnet_id = aws_subnet.tf-pubsub.id
  key_name = aws_key_pair.festine-tf-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.festine-tf-SG.id]

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host = self.public_ip
  }

  provisioner "file" {
    source = "nodejs.sh"
    destination = "/tmp/nodejs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/nodejs.sh",
      "sudo /tmp/nodejs.sh args",
    ]
  }

  tags = {
    Name = "festine-tf-instance"
  }
}

output "aws_public_ip" {
  value = aws_instance.festine-tf-ec2.public_ip
}