#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Creating Route Tables per VPC..."

PUBLIC_RT_IDS=()
PRIVATE_RT_IDS=()

# Safe array conversion
IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"
IFS=' ' read -r -a IGW_ARRAY <<< "$IGW_IDS"
IFS=' ' read -r -a PUBLIC_SUBNET_ARRAY <<< "$PUBLIC_SUBNET_IDS"
IFS=' ' read -r -a PRIVATE_SUBNET_ARRAY <<< "$PRIVATE_SUBNET_IDS"

COUNT=${#VPC_ARRAY[@]}

# Validate alignment
if [ "$COUNT" -eq 0 ] || \
   [ "$COUNT" -ne "${#IGW_ARRAY[@]}" ] || \
   [ "$COUNT" -ne "${#PUBLIC_SUBNET_ARRAY[@]}" ] || \
   [ "$COUNT" -ne "${#PRIVATE_SUBNET_ARRAY[@]}" ]; then
  echo "ERROR: Resource count mismatch"
  exit 1
fi

for ((i=0; i<COUNT; i++)); do
  INDEX=$((i+1))

  VPC_ID="${VPC_ARRAY[$i]}"
  IGW_ID="${IGW_ARRAY[$i]}"
  PUBLIC_SUBNET_ID="${PUBLIC_SUBNET_ARRAY[$i]}"
  PRIVATE_SUBNET_ID="${PRIVATE_SUBNET_ARRAY[$i]}"

  PUBLIC_RT_NAME="$NTIER_RT_PUBLIC_${INDEX}"
  PRIVATE_RT_NAME="$NTIER_RT_PRIVATE_${INDEX}"

  echo "VPC: $VPC_ID"

  # -------- Public Route Table --------
  PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTable.RouteTableId' \
    --output text)

  aws ec2 create-tags \
    --resources "$PUBLIC_RT_ID" \
    --tags Key=Name,Value="$PUBLIC_RT_NAME" \
    --region "$REGION"

  aws ec2 create-route \
    --route-table-id "$PUBLIC_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID" \
    --region "$REGION"

  aws ec2 associate-route-table \
    --route-table-id "$PUBLIC_RT_ID" \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --region "$REGION"

  # -------- Private Route Table --------
  PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTable.RouteTableId' \
    --output text)

  aws ec2 create-tags \
    --resources "$PRIVATE_RT_ID" \
    --tags Key=Name,Value="$PRIVATE_RT_NAME" \
    --region "$REGION"

  aws ec2 associate-route-table \
    --route-table-id "$PRIVATE_RT_ID" \
    --subnet-id "$PRIVATE_SUBNET_ID" \
    --region "$REGION"

  PUBLIC_RT_IDS+=("$PUBLIC_RT_ID")
  PRIVATE_RT_IDS+=("$PRIVATE_RT_ID")

  echo "  Public RT : $PUBLIC_RT_ID ($PUBLIC_RT_NAME)"
  echo "  Private RT: $PRIVATE_RT_ID ($PRIVATE_RT_NAME)"
done

# Export route table IDs
echo "export PUBLIC_RT_IDS=\"${PUBLIC_RT_IDS[*]}\""
echo "export PRIVATE_RT_IDS=\"${PRIVATE_RT_IDS[*]}\""
