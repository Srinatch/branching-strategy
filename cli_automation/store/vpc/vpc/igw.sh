#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$(dirname "$0")/../config.properties"
source "$CONFIG_FILE"

echo "Creating Internet Gateways..." >&2

IGW_IDS=()

# Safe array conversion
IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"

INDEX=1
for VPC_ID in "${VPC_ARRAY[@]}"; do
  IGW_NAME_TAG="${IGW_NAME}_${INDEX}"

  echo "VPC: $VPC_ID → IGW: $IGW_NAME_TAG" >&2

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

#  ONLY this goes to stdout
echo "export IGW_IDS=\"${IGW_IDS[*]}\""
