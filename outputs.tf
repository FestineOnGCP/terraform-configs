output "aws_public_ip" {
  value = aws_instance.festine-tf-ec2.public_ip
}

output "aws_ami_id" {
  value = data.aws_ami.ubuntu.id
}