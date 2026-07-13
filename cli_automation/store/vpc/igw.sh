#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Creating Internet Gateways per VPC..."

IGW_NAME="$IGW_NAME"
IGW_IDS=()

# Convert VPC_IDS string to array safely
IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"

if [ "${#VPC_ARRAY[@]}" -eq 0 ]; then
  echo "ERROR: No VPC IDs found"
  exit 1
fi

INDEX=1
for VPC_ID in "${VPC_ARRAY[@]}"; do
  IGW_NAME_TAG="${IGW_NAME}_${INDEX}"

  echo "VPC: $VPC_ID → IGW: $IGW_NAME_TAG"

  IGW_ID=$(aws ec2 create-internet-gateway \
    --region "$REGION" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

  aws ec2 attach-internet-gateway \
    --vpc-id "$VPC_ID" \
    --internet-gateway-id "$IGW_ID" \
    --region "$REGION"

  aws ec2 create-tags \
    --resources "$IGW_ID" \
    --tags Key=Name,Value="$IGW_NAME_TAG" \
    --region "$REGION"

  IGW_IDS+=("$IGW_ID")
  INDEX=$((INDEX + 1))
done

# Export IGW IDs
echo "export IGW_IDS=\"${IGW_IDS[*]}\""
