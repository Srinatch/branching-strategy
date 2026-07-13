#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Creating subnets per VPC..."

PUBLIC_SUBNET_IDS=()
PRIVATE_SUBNET_IDS=()

# Convert space-separated VPC_IDS to array
IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"

for i in "${!VPC_ARRAY[@]}"; do
  VPC_ID="${VPC_ARRAY[$i]}"
  INDEX=$((i+1))

  PUBLIC_SUBNET_NAME="${PUBLIC_SUBNET_NAME}-${INDEX}"
  PRIVATE_SUBNET_NAME="${PRIVATE_SUBNET_NAME}-${INDEX}"

  # Get CIDRs per VPC
  PUBLIC_CIDR="${PUBLIC_SUBNET_CIDRS[$i]}"
  PRIVATE_CIDR="${PRIVATE_SUBNET_CIDRS[$i]}"

  echo "VPC: $VPC_ID"
  echo "  Creating $PUBLIC_SUBNET_NAME  -> $PUBLIC_CIDR"
  echo "  Creating $PRIVATE_SUBNET_NAME -> $PRIVATE_CIDR"

  # Public subnet
  PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PUBLIC_CIDR" \
    --availability-zone "$AZ" \
    --region "$REGION" \
    --query 'Subnet.SubnetId' \
    --output text)

  aws ec2 modify-subnet-attribute \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --map-public-ip-on-launch \
    --region "$REGION"

  aws ec2 create-tags \
    --resources "$PUBLIC_SUBNET_ID" \
    --tags Key=Name,Value="$PUBLIC_SUBNET_NAME" \
    --region "$REGION"

  # Private subnet
  PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PRIVATE_CIDR" \
    --availability-zone "$AZ" \
    --region "$REGION" \
    --query 'Subnet.SubnetId' \
    --output text)

  aws ec2 create-tags \
    --resources "$PRIVATE_SUBNET_ID" \
    --tags Key=Name,Value="$PRIVATE_SUBNET_NAME" \
    --region "$REGION"

  PUBLIC_SUBNET_IDS+=("$PUBLIC_SUBNET_ID")
  PRIVATE_SUBNET_IDS+=("$PRIVATE_SUBNET_ID")
done

# Export subnet IDs
echo "export PUBLIC_SUBNET_IDS=\"${PUBLIC_SUBNET_IDS[*]}\""
echo "export PRIVATE_SUBNET_IDS=\"${PRIVATE_SUBNET_IDS[*]}\""
