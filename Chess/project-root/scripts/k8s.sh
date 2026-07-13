#!/bin/bash
set -ex

source scripts/common.sh

echo "Deploying to Kubernetes..."

kubectl apply -f kubernetes/namespace.yaml

kubectl apply -n $NAMESPACE -f kubernetes/

echo "Waiting for rollout..."
kubectl rollout status deployment/chess-app -n $NAMESPACE

echo "Kubernetes deployment complete ✅"