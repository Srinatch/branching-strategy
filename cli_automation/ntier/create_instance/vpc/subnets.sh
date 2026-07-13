#!/usr/bin/env bash
set -euo pipefail

source config.properties

# ---- Guard checks ----
: "${VPC_IDS:?VPC_IDS not set}"
: "${PUBLIC_SUBNET_CIDRS:?PUBLIC_SUBNET_CIDRS not set}"
: "${PRIVATE_SUBNET_CIDRS:?PRIVATE_SUBNET_CIDRS not set}"
: "${AZ:?AZ not set}"
: "${REGION:?REGION not set}"

# ---- Convert to arrays safely ----
IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"
PUBLIC_SUBNET_CIDRS=("${PUBLIC_SUBNET_CIDRS[@]}")
PRIVATE_SUBNET_CIDRS=("${PRIVATE_SUBNET_CIDRS[@]}")

# ---- Safety check ----
if [[ ${#VPC_ARRAY[@]} -ne ${#PUBLIC_SUBNET_CIDRS[@]} ]] || \
   [[ ${#VPC_ARRAY[@]} -ne ${#PRIVATE_SUBNET_CIDRS[@]} ]]; then
  echo "ERROR: VPC and Subnet CIDR count mismatch" >&2
  exit 1
fi

echo "Creating Subnets..." >&2

PUBLIC_SUBNET_IDS=()
PRIVATE_SUBNET_IDS=()

for i in "${!VPC_ARRAY[@]}"; do
  INDEX=$((i+1))
  VPC_ID="${VPC_ARRAY[$i]}"

  PUBLIC_SUBNET_NAME="${PUBLIC_SUBNET_NAME}-${INDEX}"
  PRIVATE_SUBNET_NAME="${PRIVATE_SUBNET_NAME}-${INDEX}"

  PUBLIC_CIDR="${PUBLIC_SUBNET_CIDRS[$i]}"
  PRIVATE_CIDR="${PRIVATE_SUBNET_CIDRS[$i]}"

  echo "VPC: $VPC_ID" >&2
  echo "  Public  -> $PUBLIC_SUBNET_NAME ($PUBLIC_CIDR)" >&2
  echo "  Private -> $PRIVATE_SUBNET_NAME ($PRIVATE_CIDR)" >&2

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

# ---- ONLY exports to stdout ----
echo "export PUBLIC_SUBNET_IDS=\"${PUBLIC_SUBNET_IDS[*]}\""
echo "export PRIVATE_SUBNET_IDS=\"${PRIVATE_SUBNET_IDS[*]}\""
