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

# locals {
#   ports-in = [for item in var.ports : {"port" = item["port"], "tag" = item["tag"]}]
# }

resource "aws_security_group" "festine-tf-SG" {
  name = "festine-tf-SG"
  description = "Security group for VMs created by Terraform"
  vpc_id = aws_vpc.festine-tf-vpc.id

  dynamic "ingress" {
    for_each = var.ports

    content {
      description = ingress.value["tag"]
      from_port = ingress.value["port"]
      to_port = ingress.value["port"]
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
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
  public_key = file("${var.pub_key}")
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
    private_key = file("${var.priv_key}")
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



# this is used to create an S3 bucket and a DynamoDB for managing terraform.tfstate file.
resource "aws_s3_bucket" "backend" {
  bucket = "festine-tf-985729960198-bucket"
  
  tags = {
    Name = "festine-tf-985729960198-bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_acl" "pub" {
  bucket = aws_s3_bucket.backend.id
  acl = "public-read-write"
}

resource "aws_s3_bucket_versioning" "my-versioning" {
  bucket = aws_s3_bucket.backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# the dynamodb is used for stat locking so that it only allows one access at a time
resource "aws_dynamodb_table" "state-lock-tbl" {
  name = "tfstate-lock"
  hash_key ="LockID"
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }
}