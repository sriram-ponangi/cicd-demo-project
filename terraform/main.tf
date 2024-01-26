provider "aws" {
  region = "us-east-2"  # Specify your desired AWS region
}

resource "aws_instance" "example" {
  ami           = "ami-09694bfab577e90b0"  # Specify your desired AMI ID
  instance_type = "t3a.xlarge"  # Specify your desired instance type
  key_name      = "POC_APP_SERVER_1"  # Specify the name of your existing key pair
  vpc_security_group_ids = [aws_security_group.allow_http_https.id]  # Attach security group to EC2 instance

  user_data = file("${path.root}/configs/DevOpsAppSetup.sh")
  
  root_block_device {
    volume_size = 32  # Set the root volume size to 32 GB
  }

  tags = {
    Name = "demo-cicd-project-1"
  }
}

resource "aws_security_group" "allow_http_https" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_vpc" "default" {}
