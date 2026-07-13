#!/usr/bin/env bash
set -euo pipefail

echo "Starting Rollback..." >&2

# Load config
CONFIG_FILE="$(dirname "$0")/../config.properties"
[[ -f "$CONFIG_FILE" ]] || { echo "ERROR: config.properties not found" >&2; exit 1; }
source "$CONFIG_FILE"

command -v aws >/dev/null || { echo "ERROR: aws cli not installed" >&2; exit 1; }

# EC2 Instances
echo "Terminating EC2 instances..." >&2
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=${INSTANCE_TAG_NAME}*" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text || true)

if [[ -n "${INSTANCE_IDS:-}" ]]; then
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region "$REGION"
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region "$REGION"
fi
echo "Termineted EC2 instances..." >&2

# Discover VPCs
VPC_IDS=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=${VPC_NAMES[*]}" \
  --query 'Vpcs[].VpcId' \
  --output text || true)

if [[ -z "$VPC_IDS" ]]; then
  echo "No VPCs found. Nothing to rollback." >&2
  exit 0
fi

# Security Groups
echo "Cleaning Security Groups..." >&2
for VPC_ID in $VPC_IDS; do
  # Default SG
  DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" \
    --query 'SecurityGroups[0].GroupId' --output text || true)

  if [[ -n "$DEFAULT_SG_ID" && "$DEFAULT_SG_ID" != "None" ]]; then
    aws ec2 revoke-security-group-ingress --group-id "$DEFAULT_SG_ID" --protocol all --cidr 0.0.0.0/0 --region "$REGION" 2>/dev/null || true
    aws ec2 revoke-security-group-egress  --group-id "$DEFAULT_SG_ID" --protocol all --cidr 0.0.0.0/0 --region "$REGION" 2>/dev/null || true
  fi

echo "Cleaned Security Groups..." >&2

  # Non-default SGs
  SG_IDS=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text || true)

  for SG_ID in $SG_IDS; do
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" || true
  done
done

# Route Tables
# Route Tables
echo "Cleaning Route Tables..." >&2
for VPC_ID in $VPC_IDS; do
  RT_IDS=$(aws ec2 describe-route-tables \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[].RouteTableId' \
    --output text || true)

  for RT_ID in $RT_IDS; do
    # Disassociate non-main associations
    ASSOC_IDS=$(aws ec2 describe-route-tables \
      --route-table-ids "$RT_ID" \
      --region "$REGION" \
      --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' \
      --output text || true)

    for ASSOC_ID in $ASSOC_IDS; do
      aws ec2 disassociate-route-table \
        --association-id "$ASSOC_ID" \
        --region "$REGION" || true
    done

    # Delete non-main route tables
    IS_MAIN=$(aws ec2 describe-route-tables \
      --route-table-ids "$RT_ID" \
      --region "$REGION" \
      --query 'RouteTables[0].Associations[?Main==`true`]' \
      --output text || true)

    if [[ -z "$IS_MAIN" ]]; then
      aws ec2 delete-route-table --route-table-id "$RT_ID" --region "$REGION" || true
    fi
  done
done

# Network Interfaces
echo "Deleting Network Interfaces..." >&2
for VPC_ID in $VPC_IDS; do
  ENI_IDS=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkInterfaces[].NetworkInterfaceId' --output text || true)
  for ENI_ID in $ENI_IDS; do
    aws ec2 delete-network-interface --network-interface-id "$ENI_ID" --region "$REGION" || true
  done
done
echo "Deleted Network Interfaces..." >&2

# Subnets
echo "Deleting Subnets..." >&2
for SUBNET_NAME in $PUBLIC_SUBNET_NAME $PRIVATE_SUBNET_NAME; do
  SUBNET_IDS=$(aws ec2 describe-subnets --region "$REGION" \
    --filters "Name=tag:Name,Values=${SUBNET_NAME}*" \
    --query 'Subnets[].SubnetId' --output text || true)
  for SUBNET_ID in $SUBNET_IDS; do
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$REGION" || true
  done
done
echo "Deleted Subnets..." >&2

# Internet Gateways
echo "Deleting Internet Gateways..." >&2
for IGW_NAME_FILTER in $IGW_NAME; do
  IGW_IDS=$(aws ec2 describe-internet-gateways --region "$REGION" \
    --filters "Name=tag:Name,Values=${IGW_NAME_FILTER}*" \
    --query 'InternetGateways[].InternetGatewayId' --output text || true)
  for IGW_ID in $IGW_IDS; do
    ATTACHED_VPCS=$(aws ec2 describe-internet-gateways --internet-gateway-ids "$IGW_ID" --region "$REGION" \
      --query 'InternetGateways[].Attachments[].VpcId' --output text || true)
    for VPC_ID in $ATTACHED_VPCS; do
      [[ -n "$VPC_ID" ]] && aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION" || true
    done
    aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$REGION" || true
  done
done
echo "Deleted Internet Gateways..." >&2


# VPC Deletion
echo "Deleting VPCs..." >&2
for VPC_ID in $VPC_IDS; do
  for i in {1..10}; do
    if aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION"; then
      break
    fi
    echo "Retrying VPC delete ($i/10) for $VPC_ID..." >&2
    sleep 15
  done
done

echo "Deleted VPCs..." >&2
echo "Rollback Completed Successfully!" >&2
