#!/usr/bin/env bash
set -euo pipefail

source config.properties

# Guard checks (required with set -u)
: "${VPC_NAMES:?VPC_NAMES not set in config.properties}"
: "${VPC_CIDRS:?VPC_CIDRS not set in config.properties}"
: "${REGION:?REGION not set}"

# Ensure arrays
VPC_NAMES=("${VPC_NAMES[@]}")
VPC_CIDRS=("${VPC_CIDRS[@]}")

# Safety check
if [[ ${#VPC_NAMES[@]} -ne ${#VPC_CIDRS[@]} ]]; then
  echo "ERROR: VPC_NAMES and VPC_CIDRS count mismatch" >&2
  exit 1
fi

echo "Creating VPCs..." >&2

VPC_IDS=()

for i in "${!VPC_NAMES[@]}"; do
  VPC_NAME="${VPC_NAMES[$i]}"
  VPC_CIDR="${VPC_CIDRS[$i]}"

  echo "Creating VPC: $VPC_NAME ($VPC_CIDR)" >&2

  VPC_ID=$(aws ec2 create-vpc \
  --cidr-block "$VPC_CIDR" \
  --region "$REGION" \
  --query 'Vpc.VpcId' \
  --output text) || {
    echo "WARNING: Failed to create VPC $VPC_NAME, skipping..." >&2
    continue
}

  aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Name,Value="$VPC_NAME" \
    --region "$REGION"

  aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-support '{"Value":true}' \
    --region "$REGION"

  aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames '{"Value":true}' \
    --region "$REGION"

  echo "VPC created: $VPC_ID ($VPC_NAME)" >&2
  VPC_IDS+=("$VPC_ID")
done

# ONLY export goes to stdout
echo "export VPC_IDS=\"${VPC_IDS[*]}\""
