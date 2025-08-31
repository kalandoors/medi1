# Define the provider
provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

# Create a VPC
resource "aws_vpc" "web_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "web-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Automatically assign a public IP address to instances in this subnet
  availability_zone       = "us-east-1a"  # Replace with desired AZ
  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id
  tags = {
    Name = "web-igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate route table with the public subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group to allow SSH (22) and HTTP (80) access from anywhere
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.web_vpc.id
  name        = "web-server-sg"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Create EC2 instance
resource "aws_instance" "web_instance" {
  ami                         = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (replace with your AMI ID)
  instance_type               = "t2.micro"              # Instance type (change as needed)
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.web_sg.name]
  associate_public_ip_address = true  # Assign a public IP address

  tags = {
    Name = "Web-Server"
  }
  monitoring = true
}
