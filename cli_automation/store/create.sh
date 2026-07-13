#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "Using region: $REGION"

# CREATE VPC
echo "VPC creting....."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --query 'Vpc.VpcId' \
  --output text)
  echo "VPC creted and vpc id: $VPC_ID"

aws ec2 create-tags --resources $VPC_ID \
  --tags Key=Name,Value=$VPC_NAME \
  --region $REGION

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support "{\"Value\":true}" \
  --region $REGION

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames "{\"Value\":true}" \
  --region $REGION

echo "VPC created: $VPC_ID"

# SUBNETS

echo "public subnet creating......"
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_CIDR \
  --availability-zone $AZ \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)
  
aws ec2 create-tags --resources $PUBLIC_SUBNET_ID \
  --tags Key=Name,Value=$PUBLIC_SUBNET_NAME \
  --region $REGION
  
aws ec2 modify-subnet-attribute \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --map-public-ip-on-launch \
  --region "$REGION"
echo "public Subnets created: $PUBLIC_SUBNET_ID"

echo "private Subnets creating..."

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_CIDR \
  --availability-zone $AZ \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 create-tags --resources $PRIVATE_SUBNET_ID \
  --tags Key=Name,Value=$PRIVATE_SUBNET_NAME \
  --region $REGION

echo "private Subnets created: $PRIVATE_SUBNET_ID"

# INTERNET GATEWAY

echo "internet-gateway creating...."

IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $REGION

aws ec2 create-tags --resources $IGW_ID \
  --tags Key=Name,Value=$IGW_NAME \
  --region $REGION

echo "Internet Gateway attached"

# PUBLIC ROUTE TABLE

echo "public route table creating..."

PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION

aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_ID \
  --region $REGION

aws ec2 create-tags \
  --resources $PUBLIC_RT_ID \
  --tags Key=Name,Value=$PUBLIC_SUBNET_NAME \
  --region $REGION
echo "Public route table configured"

echo "Public route table created: $PUBLIC_RT_ID"

# PRIVATE ROUTE TABLE

echo "Private route table creating...."

PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RT_ID \
  --subnet-id $PRIVATE_SUBNET_ID \
  --region $REGION

aws ec2 create-tags \
  --resources $PRIVATE_RT_ID \
  --tags Key=Name,Value=$PRIVATE_SUBNET_NAME \
  --region $REGION

echo "Private route table created: $PRIVATE_RT_ID "

### Security Group

echo "sg id creating...."
SG_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name web-sg-ntier-1 \
  --description "$SG_TAG_NAME" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$SECURITY_GROUP_ID_TCP_CIDR_RANGE"

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 80 --cidr "$SECURITY_GROUP_ID_TCP_CIDR_RANGE"

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 9091 --cidr "$SECURITY_GROUP_ID_TCP_CIDR_RANGE"

aws ec2 create-tags \
  --resources "$SG_ID" \
  --tags Key=Name,Value="$SG_TAG_NAME" \
  --region "$REGION"
echo "sg id created: $SG_ID"

### Key Pair
if ! aws ec2 describe-key-pairs --region "$REGION" --key-names "$KEY_NAME" >/dev/null 2>&1; then
  echo "Creating key pair: $KEY_NAME"
  aws ec2 create-key-pair --region "$REGION" \
    --key-name "$KEY_NAME" \
    --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
  chmod 400 "$KEY_NAME.pem"
else
  echo "Using existing key pair: $KEY_NAME"
fi

### AMI
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
  --output text)

### create instance

echo "instance creating...."
TAG_NAME="$INSTANCE_TAG_NAME"

INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --user-data file://jenkins-setup.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$TAG_NAME\"}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "EC2 Instance created: $INSTANCE_ID"

aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"
