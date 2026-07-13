#!/bin/bash
set -e

# Ensure PATH is set
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "=== Updating system ==="
apt update -y

echo "=== Installing prerequisites ==="
apt install -y ca-certificates curl gnupg lsb-release

echo "=== Adding Docker GPG key ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "=== Adding Docker repository ==="
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

echo "=== Installing Docker ==="
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io \
docker-buildx-plugin docker-compose-plugin

echo "=== Starting Docker ==="
systemctl enable docker
systemctl start docker

echo "=== Adding user to docker group ==="
usermod -aG docker ${SUDO_USER:-$(whoami)}

echo "=== Verifying Docker ==="
docker --version

echo "=== Docker installed successfully ==="
