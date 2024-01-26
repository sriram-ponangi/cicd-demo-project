#!/bin/bash

sudo su -

yum update
yum install -y docker 

wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
chmod -v +x /usr/local/bin/docker-compose
systemctl status docker.service
systemctl enable docker.service
systemctl start docker.service

docker version
docker-compose version

docker network create devops-network

docker run -d --restart unless-stopped \
--name jenkins \
--net devops-network \
--env JENKINS_OPTS="--prefix=/app/jenkins" \
-v jenkins:/var/jenkins_home \
docker.io/jenkins/jenkins:lts-jdk17

docker run -d --restart unless-stopped \
--name nexus \
--net devops-network \
-v nexus-data:/nexus-data \
--env NEXUS_CONTEXT="app/nexus" \
docker.io/sonatype/nexus3

docker run -d --restart unless-stopped \
-v sonarqube_data:/opt/sonarqube/data \
-v sonarqube_extensions:/opt/sonarqube/extensions \
-v sonarqube_logs:/opt/sonarqube/logs \
--net devops-network \
--env SONAR_WEB_CONTEXT="/app/sonarqube" \
--name sonarqube \
docker.io/sonarqube:10.3.0-community

docker run -d -p 80:80 --restart unless-stopped \
--name nginx  \
-v nginx:/etc/nginx \
--net devops-network \
sriramponangi/cicd-apps-reverse-proxy:latest