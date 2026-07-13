#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Creating EC2 instances..."

INSTANCE_IDS=()

# Safe array conversion
IFS=' ' read -r -a PUBLIC_SUBNET_ARRAY <<< "$PUBLIC_SUBNET_IDS"
IFS=' ' read -r -a SG_ARRAY <<< "$SG_IDS"

COUNT=${#PUBLIC_SUBNET_ARRAY[@]}

# Validate inputs
if [ "$COUNT" -eq 0 ] || [ "$COUNT" -ne "${#SG_ARRAY[@]}" ]; then
  echo "ERROR: Subnet and SG count mismatch or empty"
  exit 1
fi

for ((i=0; i<COUNT; i++)); do
  SUBNET_ID="${PUBLIC_SUBNET_ARRAY[$i]}"
  SG_ID="${SG_ARRAY[$i]}"
  INSTANCE_TAG="$INSTANCE_TAG="$INSTANCE_TAG_NAME""

  echo "Creating EC2 in Subnet: $SUBNET_ID with SG: $SG_ID as $INSTANCE_TAG"

  INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --user-data file://jenkins/agents/setup-jenkins_java_agent.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$INSTANCE_TAG\"}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

  echo "EC2 Instance created: $INSTANCE_ID ($INSTANCE_TAG)"

  INSTANCE_IDS+=("$INSTANCE_ID")
done

# Export instance IDs
echo "export INSTANCE_IDS=\"${INSTANCE_IDS[*]}\""
