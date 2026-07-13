#!/usr/bin/env bash
set -euo pipefail

source config.properties

echo "========================================"
echo " Starting AWS VPC Cleanup Script"
echo " Region  : $REGION"
echo " VPC     : $VPC_NAME"
echo "========================================"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region "$REGION")

[[ "$VPC_ID" == "None" ]] && { echo "VPC not found"; exit 1; }

echo " VPC Found: $VPC_ID"

# EC2 instance

echo "instance terminating..."

INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text \
  --region "$REGION")

if [[ -n "$INSTANCE_IDS" ]]; then
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region "$REGION"
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region "$REGION"
fi
echo "instance terminated: $INSTANCE_IDS"

# IGW
echo "igw cleaning..."
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text \
  --region "$REGION")

if [[ "$IGW_ID" != "None" ]]; then
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION"
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$REGION"
fi
echo "igw id cleaned: $IGW_ID"

# ROUTE TABLES

echo "Route tables deleting..."

# Get all non-main route table IDs
RT_IDS=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Associations[?Main==`false`]].RouteTableId' \
  --output text \
  --region "$REGION")

for rt in $RT_IDS; do
  echo "Processing route table: $rt"

  # Get all routes except the local route
  ROUTE_CIDRS=$(aws ec2 describe-route-tables \
  --route-table-ids "$rt" \
  --query 'RouteTables[0].Routes[?DestinationCidrBlock!=`local`].DestinationCidrBlock' \
  --output text \
  --region "$REGION")


  # Delete default routes 
  for cidr in $ROUTE_CIDRS; do
    echo "Deleting route $cidr from $rt"
    aws ec2 delete-route --route-table-id "$rt" --destination-cidr-block "$cidr" --region "$REGION" || true
  done

  # Disassociate any associations
  RT_ASSOCS=$(aws ec2 describe-route-tables \
    --route-table-ids "$rt" \
    --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' \
    --output text \
    --region "$REGION")

  for a in $RT_ASSOCS; do
    echo "Disassociating route table $rt from association $a"
    aws ec2 disassociate-route-table --association-id "$a" --region "$REGION" || true
  done

  # Delete the route table
  echo "Deleting route table: $rt"
  aws ec2 delete-route-table --route-table-id "$rt" --region "$REGION"
done

echo "Route tables deleted: $RT_IDS"

# Network Interfaces

ENI_INFO=$(aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[].NetworkInterfaceId' \
  --output text \
  --region "$REGION" || true)

if [[ -n "${ENI_INFO:-}" ]]; then
  for eni in $ENI_INFO; do
    aws ec2 delete-network-interface --network-interface-id "$eni" --region "$REGION" || true
  done
fi

# Subnets

echo "subnets deleting...."
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[].SubnetId' \
  --output text \
  --region "$REGION" || true)

if [[ -n "${SUBNET_IDS:-}" ]]; then
  for sn in $SUBNET_IDS; do
    aws ec2 delete-subnet --subnet-id "$sn" --region "$REGION"
  done
fi
echo "subnets deleted: $SUBNET_IDS"

# VPC ENDPOINTS
VPCE_IDS=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[].VpcEndpointId' \
  --output text \
  --region "$REGION")

[[ -n "$VPCE_IDS" ]] && aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCE_IDS --region "$REGION"

# SECURITY GROUPS

echo "securty groups deleting..."
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
  --output text \
  --region "$REGION")

for sg in $SG_IDS; do
  aws ec2 delete-security-group --group-id "$sg" --region "$REGION" || true
done
echo "securty group deleted : $SG_IDS"

# DELETE VPC

echo "vpc deleting...."
if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "VPC not found"
  exit 1
fi

aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION"
echo "VPC deleted successfully"


echo "========================================"
echo " CLEANUP COMPLETED SUCCESSFULLY"
echo "========================================"
