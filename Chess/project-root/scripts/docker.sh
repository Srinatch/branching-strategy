#!/bin/bash
set -ex

source scripts/common.sh

IMAGE_TAG=$(date +%s)

echo "Building image..."
docker build -t $DOCKER_IMAGE:$IMAGE_TAG ./app

echo "Pushing image..."
docker push $DOCKER_IMAGE:$IMAGE_TAG

# Save for k8s
echo "DOCKER_IMAGE_FULL=$DOCKER_IMAGE:$IMAGE_TAG" > image.env