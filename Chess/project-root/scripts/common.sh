#!/bin/bash
set -ex

# Load env
source secrets/credentials.env
source config/app.env

# 🔐 Prompt AWS creds only if empty
if [ -z "$AWS_ACCESS_KEY" ]; then
  read -p "Enter AWS Access Key: " AWS_ACCESS_KEY
fi

if [ -z "$AWS_SECRET_KEY" ]; then
  read -sp "Enter AWS Secret Key: " AWS_SECRET_KEY
  echo
fi

# Configure AWS only if not already configured
if ! aws sts get-caller-identity &> /dev/null; then
  aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
  aws configure set aws_secret_access_key "$AWS_SECRET_KEY"
  aws configure set region "$AWS_REGION"
  echo "✅ AWS configured"
else
  echo "✅ AWS already configured"
fi

# Better Docker login check
if ! docker system info | grep -i username > /dev/null; then
  echo "🔐 Docker login required"
  read -sp "Enter Docker Password: " DOCKER_PASS
  echo
  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USERNAME" --password-stdin
else
  echo "✅ Docker already logged in"
fi

# ❌ Error handler
error_handler() {
  echo "❌ ERROR at line $1"
  bash scripts/cleanup.sh
  exit 1
}

trap 'error_handler $LINENO' ERR