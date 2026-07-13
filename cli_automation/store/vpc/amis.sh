#!/usr/bin/env bash
set -euo pipefail

source config.properties

AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images | sort_by(@,&CreationDate)[-1].ImageId' \
  --output text)

echo "AMI_ID=$AMI_ID"
