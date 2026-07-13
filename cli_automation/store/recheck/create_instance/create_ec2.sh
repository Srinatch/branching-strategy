#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --user-data file://agents/setup-jenkins_java_agent.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_TAG_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"

echo "INSTANCE_ID=$INSTANCE_ID"
