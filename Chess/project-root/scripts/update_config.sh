#!/bin/bash
set -ex

source scripts/common.sh

# Check image.env exists
if [ ! -f image.env ]; then
  echo "❌ image.env not found. Docker step may have failed."
  exit 1
fi

source image.env

echo "🔄 Updating Kubernetes image..."

# Absolute safe path
DEPLOY_FILE="kubernetes/deployment.yaml"

# Replace only container image line safely
sed -i "s|image: .*|image: $DOCKER_IMAGE_FULL|g" $DEPLOY_FILE
sed -i "s|replicas:.*|replicas: $REPLICAS|g" kubernetes/deployment.yaml

echo "✅ Deployment updated with image: $DOCKER_IMAGE_FULL"