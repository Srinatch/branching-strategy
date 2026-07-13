#!/bin/bash
set -ex

echo "🧹 Cleaning resources..."

# Delete Kubernetes
kubectl delete -f kubernetes/ --ignore-not-found=true || true

# Destroy Terraform
cd terraform
terraform refresh || true
terraform destroy -auto-approve || true

echo "Cleanup completed"