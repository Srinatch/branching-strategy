#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Creating Security Groups per VPC..."

SG_BASE_NAME="$SG_TAG_NAME"
SG_COUNT="$SG_COUNT"

SG_IDS=()

# Convert VPC_IDS string to array safely
IFS=' ' read -r -a VPC_ARRAY <<< "$VPC_IDS"

for ((v=0; v<${#VPC_ARRAY[@]}; v++)); do
  VPC_ID="${VPC_ARRAY[$v]}"
  echo "VPC: $VPC_ID"

  for ((i=1; i<=SG_COUNT; i++)); do
    if [ "$i" -eq 1 ]; then
      SG_NAME="${SG_BASE_NAME}_$((v+1))"
    else
      SG_NAME="${SG_BASE_NAME}_$((v+1))_$i"
    fi

    # Check if SG exists
    EXISTING_SG=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=$SG_NAME" \
      --query 'SecurityGroups[0].GroupId' \
      --output text)

    if [[ "$EXISTING_SG" != "None" ]]; then
        echo "  SG $SG_NAME already exists: $EXISTING_SG"
        SG_IDS+=("$EXISTING_SG")
        continue
    fi

    echo "  Creating SG: $SG_NAME"
    SG_ID=$(aws ec2 create-security-group \
      --group-name "$SG_NAME" \
      --description "$SG_NAME" \
      --vpc-id "$VPC_ID" \
      --region "$REGION" \
      --query 'GroupId' \
      --output text)

    for PORT in 22 80 9091; do
      aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port "$PORT" \
        --cidr "$SECURITY_GROUP_ID_TCP_CIDR_RANGE" \
        --region "$REGION"
    done

    echo "  SG created: $SG_ID ($SG_NAME)"
    SG_IDS+=("$SG_ID")
  done
done

# Export SG IDs
echo "export SG_IDS=\"${SG_IDS[*]}\""
