#!/bin/bash
set -e

cd terraform

echo "Initializing Terraform..."
terraform init

echo "Applying Terraform..."
terraform apply -auto-approve

echo "Terraform applied ✅"