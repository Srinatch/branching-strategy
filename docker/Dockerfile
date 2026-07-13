FROM ubuntu:24.04

# Install dependencies + Java
RUN apt-get update && apt-get install -y \
    ca-certificates \
    wget \
    gnupg \
    openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Jenkins
RUN mkdir -p /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
    && echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
       > /etc/apt/sources.list.d/jenkins.list \
    && apt-get update \
    && apt-get install -y jenkins \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

CMD ["java", "-jar", "/usr/share/jenkins/jenkins.war"]
