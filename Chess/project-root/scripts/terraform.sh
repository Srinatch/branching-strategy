#!/bin/bash
set -ex

source scripts/common.sh

echo "☁️ Running Terraform (EC2)..."

cd terraform/ec2

terraform init
terraform validate
terraform apply -auto-approve

cd -

echo "✅ EC2 Provisioned"