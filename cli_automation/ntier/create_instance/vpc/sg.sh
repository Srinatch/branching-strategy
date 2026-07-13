#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$(cd "$(dirname "$0")/../.." && pwd)/config.properties"
source "$CONFIG_FILE"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: config.properties not found at $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"

# Validation (inputs come from create.sh)
command -v aws >/dev/null || {
  echo "ERROR: aws cli not installed" >&2
  exit 1
}

: "${REGION:?REGION not exported from create.sh}"
: "${VPC_IDS:?VPC_IDS not exported from create.sh}"
: "${SG_COUNT:?SG_COUNT not exported from create.sh}"
: "${SG_TAG_NAME:?SG_TAG_NAME not exported from create.sh}"
: "${SECURITY_GROUP_ID_TCP_CIDR_RANGE:?SECURITY_GROUP_ID_TCP_CIDR_RANGE missing}"

# Optional ports
SG_PORTS="${SG_PORTS:-22 80 9091 8080}"

echo "Creating Security Groups..." >&2
echo "Region : $REGION" >&2
echo "VPCs   : $VPC_IDS" >&2
echo "SG cnt : $SG_COUNT" >&2
echo "Ports  : $SG_PORTS" >&2

IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"
IFS=' ' read -r -a PORT_ARRAY <<< "$SG_PORTS"

SG_IDS=()

# Create SGs
for vpc_index in "${!VPC_ARRAY[@]}"; do
  VPC_ID="${VPC_ARRAY[$vpc_index]}"
  echo "VPC: $VPC_ID" >&2

  for ((i=1; i<=SG_COUNT; i++)); do

    if [[ "$SG_COUNT" -eq 1 ]]; then
      SG_NAME="${SG_TAG_NAME}-$((vpc_index+1))"
    else
      SG_NAME="${SG_TAG_NAME}-$((vpc_index+1))-$i"
    fi

    EXISTING_SG=$(aws ec2 describe-security-groups \
      --region "$REGION" \
      --filters \
        "Name=group-name,Values=$SG_NAME" \
        "Name=vpc-id,Values=$VPC_ID" \
      --query 'SecurityGroups[0].GroupId' \
      --output text)

    if [[ "$EXISTING_SG" != "None" && -n "$EXISTING_SG" ]]; then
      echo "Exists: $SG_NAME ($EXISTING_SG)" >&2
      SG_IDS+=("$EXISTING_SG")
      continue
    fi

    echo "Creating: $SG_NAME" >&2

    SG_ID=$(aws ec2 create-security-group \
      --group-name "$SG_NAME" \
      --description "$SG_NAME" \
      --vpc-id "$VPC_ID" \
      --region "$REGION" \
      --query 'GroupId' \
      --output text)

    for PORT in "${PORT_ARRAY[@]}"; do
      aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port "$PORT" \
        --cidr "$SECURITY_GROUP_ID_TCP_CIDR_RANGE" \
        --region "$REGION" \
        2>/dev/null || true
    done

    echo "Created: $SG_ID ($SG_NAME)" >&2
    SG_IDS+=("$SG_ID")
  done
done

# STDOUT ONLY (for create.sh)
echo "export SG_IDS=\"${SG_IDS[*]}\""
