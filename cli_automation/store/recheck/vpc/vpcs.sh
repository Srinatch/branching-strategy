#!/usr/bin/env bash
set -euo pipefail

echo "Creating VPCs..."

# Array of VPC name suffixes
VPC_NAMES=("ntier-1" "ntier-2")

# Optional: store created VPC IDs
VPC_IDS=()

for VPC_NAME in "${VPC_NAMES[@]}"; do
  echo "Creating VPC: $VPC_NAME"

  VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --region "$REGION" \
    --query 'Vpc.VpcId' \
    --output text)

  aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Name,Value="$VPC_NAME" \
    --region "$REGION"

  aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-support "{\"Value\":true}" \
    --region "$REGION"

  aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames "{\"Value\":true}" \
    --region "$REGION"

  echo "VPC created: $VPC_ID ($VPC_NAME)"

  VPC_IDS+=("$VPC_ID")
done

# Export all VPC IDs (space-separated)
echo "export VPC_IDS=\"${VPC_IDS[*]}\""
