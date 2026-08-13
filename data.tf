data "aws_availability_zones" "primary_available_az" {
  state    = "available"
  provider = aws.primary
}


data "aws_availability_zones" "secondary_available_az" {
  state    = "available"
  provider = aws.secondary
}


data "aws_ami" "primary_ami" {
  most_recent = true
  owners      = ["099720109477"]
  provider    = aws.primary

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



data "aws_ami" "secondary_ami" {
  most_recent = true
  owners      = ["099720109477"]
  provider    = aws.secondary

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}