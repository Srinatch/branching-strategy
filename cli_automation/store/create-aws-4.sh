#!/bin/bash
# script working 
set -euo pipefail

REGION="us-east-1" 
AZ="us-east-1a"     
INSTANCE_TYPE="t3.micro"
KEY_NAME="devops"
VPC_CIDR = "10.10.0.0/16"
PUBLIC_SUBNET_VPC_CIDR = "10.10.1.0/24"
PRIVATE_SUBNET_VPC_CIDR = "10.10.2.0/24"
RT_IGW_CIDR = "0.0.0.0/0"
TCP_PORT22_CIDR_RANGE = "0.0.0.0/0"


### VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --region "$REGION" \
  --cidr-block "$VPC_CIDR" \
  --query 'Vpc.VpcId' \
  --output text)

aws ec2 create-tags --region "$REGION" --resources "$VPC_ID" --tags Key=Name,Value=ntier-1
aws ec2 modify-vpc-attribute --region "$REGION" --vpc-id "$VPC_ID" --enable-dns-support
aws ec2 modify-vpc-attribute --region "$REGION" --vpc-id "$VPC_ID" --enable-dns-hostnames

### IGW
#IGW_ID=$(aws ec2 create-internet-gateway --region "$REGION" \
  --query 'InternetGateway.InternetGatewayId' --output text)

#aws ec2 attach-internet-gateway --region "$REGION" \
  --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

### Subnet
# Public subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --region "$REGION" \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PUBLIC_SUBNET_VPC_CIDR" \
  --availability-zone "$AZ" \
  --query 'Subnet.SubnetId' \
  --output text)

aws ec2 modify-subnet-attribute \
  --region "$REGION" \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --map-public-ip-on-launch

# private Subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --region "$REGION" \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_SUBNET_VPC_CIDR" \
  --availability-zone "$AZ" \
  --query 'Subnet.SubnetId' \
  --output text)
  
### Route Table
RT_ID=$(aws ec2 create-route-table --region "$REGION" \
  --vpc-id "$VPC_ID" \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route \
  --region "$REGION" \
  --route-table-id "$RT_ID" \
  --destination-cidr-block "$RT_IGW_CIDR" \
  --gateway-id "$IGW_ID"

aws ec2 associate-route-table \
  --region "$REGION" \
  --route-table-id "$RT_ID" \
  --subnet-id "$PUBLIC_SUBNET_ID"


### Security Group
WEB_SG_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name web-sg-ntier-1 \
  --description "Web SG" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$WEB_SG_ID" --protocol tcp --port 22 --cidr "$TCP_PORT22_CIDR_RANGE"

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$WEB_SG_ID" --protocol tcp --port 80 --cidr "$TCP_PORT22_CIDR_RANGE"

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
#AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
  --output text)

### create instance
  TAG_NAME="web-1"

 # INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$WEB_SG_ID" \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "EC2 Instance created: $INSTANCE_ID"
