#!/bin/bash

# Update system packages
sudo apt update -y

# Install Java
sudo apt install openjdk-17-jdk -y

# Verify Java installation
java -version

# Download Maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# Extract Maven
tar -xvf apache-maven-3.9.6-bin.tar.gz

# Move Maven to /opt directory
sudo mv apache-maven-3.9.6 /opt/maven

# Set Maven environment variables
echo "export MAVEN_HOME=/opt/maven" >> ~/.bashrc
echo "export PATH=\$MAVEN_HOME/bin:\$PATH" >> ~/.bashrc

# Apply environment changes
source ~/.bashrc

# Verify Maven installation
mvn -version