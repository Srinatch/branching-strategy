#!/bin/bash
set -e

echo "========== SYSTEM UPDATE =========="
sudo apt update -y

echo "========== INSTALL BASIC TOOLS =========="
sudo apt install -y wget curl git unzip

# ------------------------------------------------
# INSTALL JAVA
# ------------------------------------------------
echo "========== INSTALLING JAVA =========="
sudo apt install -y fontconfig openjdk-21-jre
 
JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

cat <<EOF | sudo tee /etc/profile.d/java.sh
export JAVA_HOME=${JAVA_HOME_PATH}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

sudo chmod +x /etc/profile.d/java.sh

export JAVA_HOME=${JAVA_HOME_PATH}
export PATH=$JAVA_HOME/bin:$PATH

# ------------------------------------------------
# INSTALL MAVEN
# ------------------------------------------------
echo "========== INSTALLING MAVEN =========="
sudo apt install -y maven

# ------------------------------------------------
# INSTALL PYTHON
# ------------------------------------------------
echo "========== INSTALLING PYTHON =========="
sudo apt install -y python3 python3-pip

# ------------------------------------------------
# INSTALL NODEJS
# ------------------------------------------------
echo "========== INSTALLING NODEJS =========="

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# ------------------------------------------------
# INSTALL JENKINS
# ------------------------------------------------
echo "========== INSTALLING JENKINS =========="

sudo mkdir -p /etc/apt/keyrings

wget -q -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins

# ------------------------------------------------
# CONFIGURE JENKINS PORT
# ------------------------------------------------
echo "========== CONFIGURING JENKINS PORT 9091 =========="

sudo systemctl stop jenkins || true

sudo rm -rf /etc/systemd/system/jenkins.service.d
sudo mkdir -p /etc/systemd/system/jenkins.service.d

cat <<EOF | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_HOME=${JAVA_HOME_PATH}"
ExecStart=
ExecStart=/usr/bin/java -Djava.awt.headless=true \
 -jar /usr/share/java/jenkins.war \
 --webroot=/var/cache/jenkins/war \
 --httpPort=9091 \
 --httpListenAddress=0.0.0.0
EOF

sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# ------------------------------------------------
# OPEN FIREWALL PORT
# ------------------------------------------------
echo "========== OPENING PORT 9091 =========="

sudo ufw allow 9091 || true

# ------------------------------------------------
# VERIFY INSTALLATIONS
# ------------------------------------------------
echo "========== VERIFYING TOOLS =========="

java -version
mvn -version
python3 --version
node -v
npm -v

echo "========== VERIFY JENKINS =========="

ss -tulnp | grep 9091

echo "================================================"
echo "JENKINS SUCCESSFULLY INSTALLED "
echo "Access Jenkins at:"
echo "http://<SERVER-IP>:9091"
echo "================================================"