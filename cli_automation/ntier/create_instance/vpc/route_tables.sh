#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$(cd "$(dirname "$0")/../.." && pwd)/config.properties"
source "$CONFIG_FILE"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: config.properties not found at $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"
: "${REGION:?Missing REGION}"
: "${VPC_IDS:?Missing VPC_IDS}"
: "${IGW_IDS:?Missing IGW_IDS}"
: "${PUBLIC_SUBNET_IDS:?Missing PUBLIC_SUBNET_IDS}"
: "${PRIVATE_SUBNET_IDS:?Missing PRIVATE_SUBNET_IDS}"
: "${PUBLIC_RT_BASE_NAME:?Missing PUBLIC_RT_BASE_NAME}"
: "${PRIVATE_RT_BASE_NAME:?Missing PRIVATE_RT_BASE_NAME}"

echo "Creating Route Tables..." >&2

IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"
IFS=' ' read -r -a IGW_ARRAY <<< "$IGW_IDS"
IFS=' ' read -r -a PUBLIC_SUBNET_ARRAY <<< "$PUBLIC_SUBNET_IDS"
IFS=' ' read -r -a PRIVATE_SUBNET_ARRAY <<< "$PRIVATE_SUBNET_IDS"

PUBLIC_RT_IDS=()
PRIVATE_RT_IDS=()

for i in "${!VPC_ARRAY[@]}"; do
  VPC_ID="${VPC_ARRAY[$i]}"
  IGW_ID="${IGW_ARRAY[$i]}"

  echo "VPC: $VPC_ID" >&2

  # Public RT
  PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTable.RouteTableId' \
    --output text)

  aws ec2 create-tags \
    --resources "$PUBLIC_RT_ID" \
    --tags Key=Name,Value="${PUBLIC_RT_BASE_NAME}-$((i+1))" \
    --region "$REGION" >/dev/null

  aws ec2 create-route \
    --route-table-id "$PUBLIC_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID" \
    --region "$REGION" >/dev/null 2>&1 || true

  aws ec2 associate-route-table \
    --route-table-id "$PUBLIC_RT_ID" \
    --subnet-id "${PUBLIC_SUBNET_ARRAY[$i]}" \
    --region "$REGION" >/dev/null

  PUBLIC_RT_IDS+=("$PUBLIC_RT_ID")

  # Private RT
  PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTable.RouteTableId' \
    --output text)

  aws ec2 create-tags \
    --resources "$PRIVATE_RT_ID" \
    --tags Key=Name,Value="${PRIVATE_RT_BASE_NAME}-$((i+1))" \
    --region "$REGION" >/dev/null

  aws ec2 associate-route-table \
    --route-table-id "$PRIVATE_RT_ID" \
    --subnet-id "${PRIVATE_SUBNET_ARRAY[$i]}" \
    --region "$REGION" >/dev/null

  PRIVATE_RT_IDS+=("$PRIVATE_RT_ID")
done

# STDOUT ONLY
echo "export PUBLIC_RT_IDS=\"${PUBLIC_RT_IDS[*]}\""
echo "export PRIVATE_RT_IDS=\"${PRIVATE_RT_IDS[*]}\""
