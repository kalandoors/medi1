# Define the provider
provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

# VPC Creation
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
}

# Public Subnet for Web Servers
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Choose your desired AZ
  map_public_ip_on_launch = true
}

# Private Subnet for Application Servers
resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

# Private Subnet for Database Servers
resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

# Route Table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group for Web Servers (Port 22 open to public)
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Security group for web tier"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open SSH access from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open HTTP access from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

# Security Group for Application Servers
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Security group for application tier"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public_subnet.cidr_block]  # Allow access from web subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Database Servers
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Security group for database tier"

  ingress {
    from_port   = 3306  # MySQL Port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app_subnet.cidr_block]  # Allow access from application subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web Server EC2 Instance
resource "aws_instance" "web_instance" {
  ami                         = "ami-0c55b159cbfafe1f0"  # Example Amazon Linux 2 AMI, replace as needed
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.web_sg.name]
}

# Application Server EC2 Instance
resource "aws_instance" "app_instance" {
  ami                         = "ami-0c55b159cbfafe1f0"  # Example Amazon Linux 2 AMI, replace as needed
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.app_subnet.id
  security_groups             = [aws_security_group.app_sg.name]
}

# Database Server EC2 Instance
resource "aws_instance" "db_instance" {
  ami                         = "ami-0c55b159cbfafe1f0"  # Example Amazon Linux 2 AMI, replace as needed
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.db_subnet.id
  security_groups             = [aws_security_group.db_sg.name]
}
