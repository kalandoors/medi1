provider "aws" {
  region = "us-west-2"  # Change to your preferred region
}

# Generate a new key pair locally (or provide your own key name)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "my-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  filename = "${path.module}/my-key.pem"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400"
}

# Security group to allow SSH
resource "aws_security_group" "ssh_sg" {
  name        = "allow-ssh"
  description = "Allow SSH from anywhere"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ Open to public
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (update as needed)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.ssh_sg.name]

  tags = {
    Name = "MyEC2Instance"
  }
}
