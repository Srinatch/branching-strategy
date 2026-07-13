#!/usr/bin/env bash
set -euo pipefail

echo "Creating subnets..."

PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PUBLIC_SUBNET_CIDR" \
  --availability-zone "$AZ" \
  --region "$REGION" \
  --query 'Subnet.SubnetId' --output text)

aws ec2 modify-subnet-attribute \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --map-public-ip-on-launch \
  --region "$REGION"

aws ec2 create-tags --resources "$PUBLIC_SUBNET_ID" \
  --tags Key=Name,Value="$PUBLIC_SUBNET_NAME" \
  --region "$REGION"

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_SUBNET_CIDR" \
  --availability-zone "$AZ" \
  --region "$REGION" \
  --query 'Subnet.SubnetId' --output text)

aws ec2 create-tags --resources "$PRIVATE_SUBNET_ID" \
  --tags Key=Name,Value="$PRIVATE_SUBNET_NAME" \
  --region "$REGION"

echo "PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID"
echo "PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID"
