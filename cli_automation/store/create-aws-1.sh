#!/bin/bash

set -e

REGION="us-east-1"
AZ="us-east-1a"
INSTANCE_TYPE="t3.micro"
TAG_NAME="web1"

echo "Fetching VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC_ID=$VPC_ID"

echo "Fetching Subnet ID from $AZ..."
SUBNET_ID=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=availability-zone,Values=$AZ" "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --output text)

echo "SUBNET_ID=$SUBNET_ID"

echo "Fetching Security Group ID..."
SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "SG_ID=$SG_ID"

echo "Fetching Key Pair name..."
KEY_NAME=$(aws ec2 describe-key-pairs \
  --region $REGION \
  --query 'KeyPairs[0].KeyName' \
  --output text)

echo "KEY_NAME=$KEY_NAME"

echo "Fetching latest Ubuntu 22.04 LTS AMI..."
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
  --output text)

echo "AMI_ID=$AMI_ID"

echo "Creating EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

