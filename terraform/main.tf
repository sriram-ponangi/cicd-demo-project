provider "aws" {
  region = "us-east-2"  # Specify your desired AWS region
}

resource "aws_instance" "example" {
  ami           = "ami-09694bfab577e90b0"  # Specify your desired AMI ID
  instance_type = "t3a.xlarge"  # Specify your desired instance type
  key_name      = "POC_APP_SERVER_1"  # Specify the name of your existing key pair
  vpc_security_group_ids = [aws_security_group.allow_http_https.id]  # Attach security group to EC2 instance

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update
              sudo yum install -y docker 
              wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
              sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
              sudo chmod -v +x /usr/local/bin/docker-compose
              sudo systemctl status docker.service
              sudo systemctl enable docker.service
              sudo systemctl start docker.service
              sudo docker version
              sudo docker-compose version

              sudo docker network create devops-network

              sudo docker run --rm -d --name jenkins \
              --net devops-network \
              --env JENKINS_OPTS="--prefix=/app/jenkins" \
              -v jenkins:/var/jenkins_home jenkins/jenkins:lts-jdk17

              sudo docker run --rm -d \
              --name nexus \
              --net devops-network \
              -v nexus-data:/nexus-data \
              --env NEXUS_CONTEXT="app/nexus" \
              sonatype/nexus3

              sudo docker run --rm -d \
              -v sonarqube_data:/opt/sonarqube/data \
              -v sonarqube_extensions:/opt/sonarqube/extensions \
              -v sonarqube_logs:/opt/sonarqube/logs \
              --net devops-network \
              --env SONAR_WEB_CONTEXT="/app/sonarqube" \
              --name sonarqube \
              sonarqube:10.3.0-community
                
              sudo docker run --rm -d -p 80:80 \
              -v nginx:/etc/nginx --net devops-network \
              --name nginx  nginx:1.25.3

              EOF
  
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
