#!/bin/bash
set -e

echo "=== Updating system ==="
apt update -y

echo "=== Installing Java 21 ==="
apt install -y fontconfig openjdk-21-jre

# Detect JAVA_HOME
JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed 's:/bin/java::')

# Set JAVA_HOME system-wide
cat <<EOF >/etc/profile.d/java.sh
export JAVA_HOME=${JAVA_HOME_PATH}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
chmod +x /etc/profile.d/java.sh

export JAVA_HOME=${JAVA_HOME_PATH}
export PATH=$JAVA_HOME/bin:$PATH

# JENKINS

echo "=== Adding Jenkins repository ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
| gpg --dearmor -o /etc/apt/keyrings/jenkins.gpg

echo "deb [signed-by=/etc/apt/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

echo "=== Stopping Jenkins ==="
systemctl stop jenkins || true

echo "=== Cleaning old overrides ==="
rm -rf /etc/systemd/system/jenkins.service.d

echo "=== Creating systemd ExecStart override (PORT 9091) ==="
mkdir -p /etc/systemd/system/jenkins.service.d

cat <<EOF >/etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_HOME=${JAVA_HOME_PATH}"
ExecStart=
ExecStart=/usr/bin/java -Djava.awt.headless=true \\
 -jar /usr/share/java/jenkins.war \\
 --webroot=/var/cache/jenkins/war \\
 --httpPort=9091 \\
 --httpListenAddress=0.0.0.0
EOF

echo "=== Reloading systemd and starting Jenkins ==="
systemctl daemon-reload
systemctl enable jenkins
systemctl restart jenkins

echo "=== Verifying Jenkins ==="
ps aux | grep jenkins | grep -v grep
ss -tulnp | grep 9091

echo "=== Jenkins is now running on port 9091 ==="
