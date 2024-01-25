# Setup EC2 Instance

- Login into remote AWS server using the ssh command:
    ```shell
    $ ssh -i <PEM_FILE_PATH> ec2-user@ec2-ip-address-dns-name-here
    ```
- Apply pending updates using the yum command:
    ```shell
    $ sudo yum update
    ```
- Search for Docker package:
    ```shell
    $ sudo yum search docker
    ```
- Get version information:
    ```shell
    $ sudo yum info docker
    ```
- Install docker:
    ```shell
    $ sudo yum install docker
    ```
- Install docker-compose:
    ```shell
    $ wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
    
    $ sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
    
    $ sudo chmod -v +x /usr/local/bin/docker-compose
    ```
- Start docker on VM bootup:
    ```shell
    $ sudo systemctl status docker.service

    $ sudo systemctl enable docker.service

    $ sudo systemctl start docker.service
    ```
- Verify Installed docker and docker-compose:
    ```shell
    docker version

    docker-compose version
    ```
- **References:**
    - > https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/
---
# Setup DevOps Applications

### Approach-1: With Simple Docker Commands:
- Create network to connect applications:
    ```shell
    $ docker network create devops-network
    ```

- **Jenkins CI/CD Server Setup**

    ```shell
        # Start jenkins container
        $ docker run -d --name jenkins \
            --net devops-network \
            --env JENKINS_OPTS="--prefix=/app/jenkins" \
            -v jenkins:/var/jenkins_home jenkins/jenkins:lts-jdk17
        # [Alternative]
        # Start jenkins container by exposing ports directly
        # $ docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
        #    --net devops-network \
        #    --env JENKINS_OPTS="--prefix=/app/jenkins" \
        #    -v jenkins:/var/jenkins_home jenkins/jenkins:lts-jdk17
        
        # Get Initial jenkins admin user's password
        $ docker exec jenkins bash -c "cat /var/jenkins_home/secrets/initialAdminPassword"
        # [Alternative]
        # SSH to the container and run the cat command
        # $ docker exec -it jenkins /bin/bash
        # jenkins@5fee21dbdb74:/$ cat /var/jenkins_home/secrets/initialAdminPassword

    ```
    -   Use a URL like http://ip-address/app/jenkins to access Jenkins via nginx reverse proxy (follow nginx setup instructions below). If port 8080 is exposed you can alternavitvely access the Jenkins directry by mentioning the port number like http://ip-address:8080/app/jenkins.
    

- **Sonatype Nexus Artifactory Setup**

    ```shell
        # Start Nexus container
        $ docker run -d -p 8081:8081 \
            --name nexus \
            --net devops-network \
            -v nexus-data:/nexus-data \
            --env NEXUS_CONTEXT="app/nexus" \
            sonatype/nexus3

        # Get Initial Nexus admin user's password
        # $ docker exec nexus bash -c "cat /nexus-data/admin.password"
        # [Alternative]
        # SSH to the container and run the cat command
        # $ docker exec -it nexus /bin/bash
        # nexus@5fee21dbdb74:/$ cat /nexus-data/admin.password
    ```

    - Use a URL like http://ip-address/app/nexus to access Nexus via nginx reverse proxy (follow nginx setup instructions below). If port 8081 is exposed you can alternavitvely access the Jenkins directry by mentioning the port number like http://ip-address:8081/app/nexus.

    - Credentials:
        - **Default User**: admin
        - **Default Password**: <Add file path here...> (**Sample Updated Password**: Admin@123)



- **SonarQube Code Analyzer Setup**
    ```shell
    # Start SonarQube container
    $ docker run -d \
        -p 9000:9000 \
        -v sonarqube_data:/opt/sonarqube/data \
        -v sonarqube_extensions:/opt/sonarqube/extensions \
        -v sonarqube_logs:/opt/sonarqube/logs \
        --net devops-network \
        --env SONAR_WEB_CONTEXT="/app/sonarqube" \
        --name sonarqube \
        sonarqube:10.3.0-community
    ```

    - Use a URL like http://ip-address:9000 to access JFrog directry by mentioning the port number (if port 9000 is exposed).

    - Credentials:
        - **Default User**: admin
        - **Default Password**: admin (**Sample Updated Password**: Admin@123)

    - **References:**
        - > https://stackoverflow.com/questions/38817344/how-to-persist-configuration-analytics-across-container-invocations-in-sonarqu 

- **Nginx Reverse Proxy Setup**
    ```shell
    # Start nginx container
    $ docker run -d -p 80:80 \
        -v nginx:/etc/nginx --net devops-network \
        --name nginx  nginx:1.25.3

    # NOTE: updated default.conf is uploaded to the current repository
    # Copy nginx reverse proxy configuration to container
    $ docker cp ./nginx/default.conf  nginx:/etc/nginx/conf.d/default.conf
    # [Alternative]
    # Inspect the nginx volume and edit the nginx/conf.d/default.conf file directly on host
    # $ docker volume inspect nginx 
    # Assuming the "Mountpoint": "/var/lib/docker/volumes/nginx/_data"
    # $ cp ./default.conf  /var/lib/docker/volumes/nginx/_data/conf.d/default.conf

    # Verify the syntax of nginx configs
    $ docker exec nginx bash -c "nginx -t"
    # NOTE: Get the final applied nginx config file
    # $ docker exec nginx bash -c "nginx -T" > final-nginx.conf

    # Reload new nginx configurations
    $ docker exec nginx bash -c "nginx -s reload"
    # [Alternative]
    # Restart the container
    # $ docker container restart nginx
    ```

# Monitor EC2 Instance Resource Utiluzation
- To check RAM utilization:
    ```shell
    $ free -h
    ```
- To check CPU Usage:
    ```shell
    $ top -bn2 | grep '%Cpu' | tail -1 | grep -P '(....|...) id,'|awk '{print "CPU Usage: " 100-$8 "%"}'
    ```

- To check average CPU Load:
    ```shell
    # The uptime command gives us a view of the CPU load average at 1, 5, and 15 minutes interval
    $ uptime
    # Sample Output:
    # 12:40:05 up  2:29,  1 user,  load average: 0.37, 0.08, 0.03

    # Interpreting load average can’t be done without knowing the number of cores of a system:
    $ cat /proc/cpuinfo |grep core
    # Sample Output:
    # core id		: 0
    # cpu cores	    : 1
    ```

- > **NOTE**:
  > - **CPU load** is defined as the number of processes using or waiting to use one core at a single point in time.
  > -  **CPU usage** is the percentage of time a CPU takes to process non-idle tasks. CPU Usage can only be measured over a specified interval of time. We can determine the CPU usage by taking the percentage of time spent idling and subtracting it from 100. 
  > - **Reference:** https://www.baeldung.com/linux/get-cpu-usage




Need to run this in jenkins container:
ssh-keyscan github.com >> ~/.ssh/known_hosts