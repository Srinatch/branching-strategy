#!/usr/bin/env bash
set -euo pipefail

SG_ID=$(aws ec2 create-security-group \
  --group-name web-sg-ntier \
  --description "$SG_TAG_NAME" \
  --vpc-id "$VPC_ID" \
  --region "$REGION" \
  --query 'GroupId' --output text)

for PORT in 22 80 9091; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port "$PORT" \
    --cidr "$SECURITY_GROUP_ID_TCP_CIDR_RANGE" \
    --region "$REGION"
done

echo "SG_ID=$SG_ID"
