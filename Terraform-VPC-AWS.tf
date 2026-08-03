# Configure Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/21"
  instance_tenancy = "default"

  tags = {
    Name = "own_vpc"
  }
}

# Create Management (Public) Subnet
resource "aws_subnet" "mgmt_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "management_subnet"
  }
}

# Create Database (Private) Subnet
resource "aws_subnet" "db_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "database_subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "igw"
  }
}

# Create Route Table
resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = "vfx_rt"
  }
}

# Associate Route Table with Management Subnet
resource "aws_route_table_association" "test_rt_asso" {
  subnet_id      = aws_subnet.mgmt_subnet.id
  route_table_id = aws_route_table.test_rt.id
}
# Create New S-G group........
resource "aws_security_group" "test_sg" {
  name        = "test-sg"
  description = "Common Security Group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-sg"
  }
}
#............... create Public Nw Machine .....
resource "aws_instance" "public_server" {
  ami                         = "ami-00d6a5e9ee89a3eea"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.mgmt_subnet.id
  vpc_security_group_ids      = [aws_security_group.test_sg.id]
  key_name                    = "Pazhani@12345678"
  associate_public_ip_address = true

  tags = {
    Name = "Public-Server"
  }
}
#''''''''''''''''Create private Subnet machine ............
resource "aws_instance" "private_server" {
  ami                         = "ami-00d6a5e9ee89a3eea"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.db_subnet.id
  vpc_security_group_ids      = [aws_security_group.test_sg.id]
  key_name                    = "Pazhani@12345678"
  associate_public_ip_address = false

  tags = {
    Name = "Private-Server"
  }
}
