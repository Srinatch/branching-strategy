#!/bin/bash
set -e

IMAGE_NAME="your-dockerhub-username/app:latest"  # 🔁 CHANGE THIS

echo "Building Docker image..."
docker build -t $IMAGE_NAME ./app

echo "Pushing Docker image..."
docker push $IMAGE_NAME

echo "Docker image pushed ✅"