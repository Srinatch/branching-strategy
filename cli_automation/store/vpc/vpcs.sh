#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Creating VPCs..."

# Safety check
if [[ ${#VPC_NAMES[@]} -ne ${#VPC_CIDRS[@]} ]]; then
  echo "ERROR: VPC_NAMES and VPC_CIDRS count mismatch"
  exit 1
fi

VPC_IDS=()

for i in "${!VPC_NAMES[@]}"; do
  VPC_NAME="${VPC_NAMES[$i]}"
  VPC_CIDR="${VPC_CIDRS[$i]}"

  echo "Creating VPC: $VPC_NAME ($VPC_CIDR)"

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

# Export for create.sh
echo "export VPC_IDS=\"${VPC_IDS[*]}\""
