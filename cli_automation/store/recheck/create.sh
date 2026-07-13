#!/usr/bin/env bash
set -euo pipefail

# Load configuration
source config.properties

# Export shared variables used across scripts
export REGION AZ
export SECURITY_GROUP_ID_TCP_CIDR_RANGE
export KEY_NAME INSTANCE_TYPE

echo "Starting Infrastructure Creation"

# VPC
echo "Step 1: Creating VPCs..."
eval "$(./vpc/vpcs.sh)"

[ -z "${VPC_IDS:-}" ] && { echo "ERROR: VPC creation failed"; exit 1; }
echo "VPCs created: $VPC_IDS"

# Subnets
echo "Step 2: Creating Subnets..."
eval "$(./vpc/subnets.sh)"

[ -z "${PUBLIC_SUBNET_IDS:-}" ] && { echo "ERROR: Subnet creation failed"; exit 1; }
echo "Public Subnets : $PUBLIC_SUBNET_IDS"
echo "Private Subnets: $PRIVATE_SUBNET_IDS"

# IGW
echo "Step 3: Creating Internet Gateways..."
eval "$(./vpc/igw.sh)"

[ -z "${IGW_IDS:-}" ] && { echo "ERROR: IGW creation failed"; exit 1; }
echo "IGWs created: $IGW_IDS"

# Route Tables
echo "Step 4: Creating Route Tables..."
eval "$(./vpc/route_tables.sh)"

echo "Public RT IDs : $PUBLIC_RT_IDS"
echo "Private RT IDs: $PRIVATE_RT_IDS"

# Security Groups
echo "Step 5: Creating Security Groups..."
eval "$(./vpc/sg.sh)"

echo "SG IDs created: $SG_IDS"

# Key Pair
echo "Step 6: Creating Key Pair..."
./create_instance/keypair.sh
echo "Key pair ready: $KEY_NAME.pem"

# AMI
echo "Step 7: Selecting AMI..."
eval "$(./create_instance/amis.sh)"

[ -z "${AMI_ID:-}" ] && { echo "ERROR: AMI selection failed"; exit 1; }
echo "AMI selected: $AMI_ID"

# EC2 Instances
echo "Step 8: Creating EC2 Instances..."
eval "$(./create_instance/create_ec2.sh)"

echo "EC2 Instances created: $INSTANCE_IDS"

echo "All Infrastructure Created Successfully!"

# Infra Output
cat <<EOF > infra_output.txt
# VPCs
VPC_IDS="$VPC_IDS"

# Subnets
PUBLIC_SUBNET_IDS="$PUBLIC_SUBNET_IDS"
PRIVATE_SUBNET_IDS="$PRIVATE_SUBNET_IDS"

# Internet Gateways
IGW_IDS="$IGW_IDS"

# Route Tables
PUBLIC_RT_IDS="$PUBLIC_RT_IDS"
PRIVATE_RT_IDS="$PRIVATE_RT_IDS"

# Security Groups
SG_IDS="$SG_IDS"

# Key Pair
KEY_NAME="$KEY_NAME"
KEY_FILE="$KEY_NAME.pem"

# AMI
AMI_ID="$AMI_ID"

# EC2 Instances
INSTANCE_IDS="$INSTANCE_IDS"
EOF

echo "Infrastructure details written to infra_output.txt"
