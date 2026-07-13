#!/bin/bash
set -e

echo "Starting rollback..."

# JENKINS ROLLBACK

# Stop Jenkins if running
if systemctl is-active --quiet jenkins; then
  systemctl stop jenkins
fi

# Disable Jenkins
if systemctl is-enabled --quiet jenkins; then
  systemctl disable jenkins
fi

# Remove Jenkins package
apt purge -y jenkins || true
apt autoremove -y

# Remove Jenkins repo
rm -f /etc/apt/sources.list.d/jenkins.list

# Remove Jenkins key
rm -f /etc/apt/keyrings/jenkins-keyring.asc

# Remove Jenkins default config changes
rm -f /etc/default/jenkins

# JAVA ROLLBACK

# Remove Java 21
apt purge -y openjdk-21-jre fontconfig || true
apt autoremove -y

# Remove Java environment file
rm -f /etc/profile.d/java.sh

# Remove JAVA_HOME from current session (best-effort)
unset JAVA_HOME
unset CLASSPATH
export PATH=$(echo "$PATH" | sed -e 's|/usr/lib/jvm/[^:]*/bin:||')

# SYSTEM CLEANUP

# Update apt cache
apt update -y

# Reload systemd
systemctl daemon-reload

echo "Rollback completed successfully."
