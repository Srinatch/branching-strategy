#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Starting Infrastructure Creation"

# LOAD STATIC CONFIG (ONCE)
source config.properties

# VPC
echo "Creating VPCs..."
VPC_EXPORTS="$(./create_instance/vpc/vpcs.sh)"
eval "$VPC_EXPORTS"              #eval is string as input and executes

: "${VPC_IDS:?VPC creation failed}"
echo "VPCs created: $VPC_IDS"

# SUBNETS
echo "Creating Subnets..."
SUBNET_EXPORTS="$(./create_instance/vpc/subnets.sh)"
eval "$SUBNET_EXPORTS"

: "${PUBLIC_SUBNET_IDS:?Public subnet creation failed}"
: "${PRIVATE_SUBNET_IDS:?Private subnet creation failed}"

echo "Public Subnets : $PUBLIC_SUBNET_IDS"
echo "Private Subnets: $PRIVATE_SUBNET_IDS"

# IGW
echo "Creating Internet Gateways..."
IGW_EXPORTS="$(./create_instance/vpc/igw.sh)"
eval "$IGW_EXPORTS"

: "${IGW_IDS:?IGW creation failed}"
echo "IGWs created: $IGW_IDS"

# ROUTE TABLES
echo "Creating Route Tables..."

ROUTE_EXPORTS="$(./create_instance/vpc/route_tables.sh)"

# Debug (optional, safe)
echo "DEBUG ROUTE_EXPORTS >>>" >&2
printf '%q\n' "$ROUTE_EXPORTS" >&2
echo "<<< END DEBUG" >&2

# Load exports
eval "$ROUTE_EXPORTS"

# Validate
: "${PUBLIC_RT_IDS:?Route table creation failed}"
: "${PRIVATE_RT_IDS:?Route table creation failed}"

echo "Public RT IDs : $PUBLIC_RT_IDS"
echo "Private RT IDs: $PRIVATE_RT_IDS"

echo "Route tables created successfully" >&2

# SECURITY GROUPS
echo "Creating Security Groups..."

SG_EXPORTS="$(./create_instance/vpc/sg.sh)"
eval "$SG_EXPORTS"

: "${SG_IDS:?Security group creation failed}"
echo "SG IDs created: $SG_IDS"

# KEY PAIR
echo "Creating Key Pair..."
./create_instance/keypair.sh
echo "Key pair ready: $KEY_NAME.pem"

# AMI
echo "Selecting AMI..."
AMI_EXPORTS="$("$SCRIPT_DIR/create_instance/amis.sh")"
eval "$AMI_EXPORTS"

: "${AMI_ID:?AMI selection failed}"
echo "AMI selected: $AMI_ID"

export AMI_ID SG_IDS PUBLIC_SUBNET_IDS REGION INSTANCE_TAG_NAME INSTANCE_TYPE KEY_NAME USER_DATA_FILE

# EC2
echo "Creating EC2 Instances..."
EC2_EXPORTS="$(./create_instance/create_ec2.sh)"
eval "$EC2_EXPORTS"

: "${INSTANCE_IDS:?EC2 creation failed}"
echo "EC2 Instances created: $INSTANCE_IDS"

echo "All Infrastructure Created Successfully!"

# ------------------------------------------------------------
# echo "Creating Amazon EKS Cluster..."

# export REGION KEY_NAME VPC_IDS PUBLIC_SUBNET_IDS PRIVATE_SUBNET_IDS SG_IDS

# EKS_EXPORTS="$(./create_instance/eks/create_eks_cluster.sh)

#echo "All Infrastructure + EKS Created Successfully!"