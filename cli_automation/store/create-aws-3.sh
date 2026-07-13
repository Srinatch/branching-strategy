#!/bin/bash
set -o pipefail

for i in 1 2 3; do

REGION="us-east-1"
AZ="us-east-1a"
INSTANCE_TYPE="t3.micro"
TAG_NAME="web-$i"



echo "Fetching VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC_ID=$VPC_ID"

echo "Fetching Subnet ID from $AZ..."
SUBNET_ID=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=availability-zone,Values=$AZ" "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --output text)

echo "SUBNET_ID=$SUBNET_ID"

echo "Fetching Security Group ID..."
SG_ID=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "SG_ID=$SG_ID"

KEY_NAME="hazarath"

echo "Checking key pair: $KEY_NAME"

if ! aws ec2 describe-key-pairs \
  --region "$REGION" \
  --key-names "$KEY_NAME" \
  >/dev/null 2>&1; then

  echo "Creating key pair $KEY_NAME..."
  aws ec2 create-key-pair \
    --region "$REGION" \
    --key-name "$KEY_NAME" \
    --query 'KeyMaterial' \
    --output text > "$KEY_NAME.pem"

  chmod 400 "$KEY_NAME.pem"
else
  echo "Key pair already exists: $KEY_NAME"
fi

echo "Using Key Pair: $KEY_NAME"


echo "Fetching latest Ubuntu 22.04 LTS AMI..."
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
  --output text)

echo "AMI_ID=$AMI_ID"

echo "Creating EC2 instance: $TAG_NAME"
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --subnet-id "$SUBNET_ID" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$web-1}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

done