#!/usr/bin/env bash
set -euo pipefail

# Number of IGWs to create
IGW_COUNT=2

IGW_IDS=()

for i in $(seq 1 "$IGW_COUNT"); do
  IGW_NAME_TAG="${IGW_NAME}_${i}"

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

  echo "Created IGW: $IGW_ID with tag $IGW_NAME_TAG"
done

# Export first IGW (usually needed for route table)
echo "export IGW_ID=${IGW_IDS[0]}"

