## [TODO]
- **JFrog Artifactory Setup**
    ```shell
    # Start JFrog container
    $ docker run -d -p 8081:8081 -p 8082:8082 \
        -v jfrog:/var/opt/jfrog/artifactory \
        --net devops-network \
        --name jfrog \
        releases-docker.jfrog.io/jfrog/artifactory-oss:latest
    ```

    -   Use a URL like http://ip-address:8082/ui to access JFrog directry by mentioning the port number (if port 8082 is exposed).

    - Credentials:
        - **Default User**: admin
        - **Default Password**: password (**Sample Updated Password**: Admin@123)