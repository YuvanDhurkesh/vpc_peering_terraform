resource "aws_vpc" "primary" {
  cidr_block           = var.primary_vpc_cidr
  provider             = aws.primary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "primary_vpc_${var.primary_vpc_reg}"
  }
}


resource "aws_vpc" "secondary" {
  cidr_block           = var.secondary_vpc_cidr
  provider             = aws.secondary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "secondary_vpc_${var.secondary_vpc_reg}"
  }
}


resource "aws_subnet" "primary_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = var.primary_vpc_cidr
  availability_zone       = data.aws_availability_zones.primary_available_az.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Primary_Subnet"
  }
}


resource "aws_subnet" "secondary_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = var.secondary_vpc_cidr
  availability_zone       = data.aws_availability_zones.secondary_available_az.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Secondary_Subnet"
  }
}


resource "aws_internet_gateway" "primary_igw" {
  vpc_id   = aws_vpc.primary.id
  provider = aws.primary

  tags = {
    Name = "Primary_VPC_IGW"
  }
}


resource "aws_internet_gateway" "secondary_igw" {
  vpc_id   = aws_vpc.secondary.id
  provider = aws.secondary

  tags = {
    Name = "Secondary_VPC_IGW"
  }
}


resource "aws_route_table" "primary_rt" {
  vpc_id   = aws_vpc.primary.id
  provider = aws.primary

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
    Name = "primary_rt"
  }
}


resource "aws_route_table" "secondary_rt" {
  vpc_id   = aws_vpc.secondary.id
  provider = aws.secondary

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
    Name = "secondary_rt"
  }
}


resource "aws_route_table_association" "primary_rta" {
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
  provider       = aws.primary
}


resource "aws_route_table_association" "secondary_rta" {
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
  provider       = aws.secondary
}


resource "aws_vpc_peering_connection" "primary_peer" {
  provider    = aws.primary
  peer_vpc_id = aws_vpc.secondary.id
  vpc_id      = aws_vpc.primary.id
  peer_region = var.secondary_vpc_reg
  auto_accept = false

  tags = {
    Name = "Requester-primary"
  }
}




resource "aws_vpc_peering_connection_accepter" "secondary_accpt" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter-secondary"
  }
}




resource "aws_route" "primary_route" {
  route_table_id            = aws_route_table.primary_rt.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_peer.id
  provider                  = aws.primary

  depends_on = [
    aws_vpc_peering_connection_accepter.secondary_accpt
  ]
}

resource "aws_route" "secondary_route" {
  route_table_id            = aws_route_table.secondary_rt.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_peer.id
  provider                  = aws.secondary

  depends_on = [
    aws_vpc_peering_connection_accepter.secondary_accpt
  ]
}


resource "aws_security_group" "primary_sg" {
  provider = aws.primary

  name        = "primary-vpc-sg"
  description = "Security group for Primary VPC"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Primary-SG"
  }
}


resource "aws_security_group" "secondary_sg" {
  provider = aws.secondary

  name        = "secondary-vpc-sg"
  description = "Security group for Secondary VPC"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Secondary-SG"
  }
}

resource "aws_instance" "primary_ec2" {
  ami                         = data.aws_ami.primary_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.primary_subnet.id
  vpc_security_group_ids      = [aws_security_group.primary_sg.id]
  key_name = "vpc-peering-new"
  associate_public_ip_address = true
  provider                    = aws.primary

  tags = {
    Name = "Primary EC2"
  }
}


resource "aws_instance" "secondary_ec2" {
  ami                         = data.aws_ami.secondary_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.secondary_subnet.id
  vpc_security_group_ids      = [aws_security_group.secondary_sg.id]
  key_name = "vpc-peering-ap-south-1"
  associate_public_ip_address = true
  provider                    = aws.secondary

  tags = {
    Name = "Secondary EC2"
  }
}