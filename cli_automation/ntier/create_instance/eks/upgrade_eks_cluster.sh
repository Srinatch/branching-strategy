#!/usr/bin/env bash
set -euo pipefail

# Amazon EKS Upgrade Script

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.properties"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: config.properties not found"
    exit 1
fi

source "$CONFIG_FILE"

# Validation

command -v aws >/dev/null || {
    echo "ERROR: aws cli not installed"
    exit 1
}

command -v kubectl >/dev/null || {
    echo "ERROR: kubectl not installed"
    exit 1
}

aws sts get-caller-identity >/dev/null

# Variables

CLUSTER_NAME="ntier-eks"

CURRENT_VERSION="1.34"

TARGET_VERSION="1.35"

NODEGROUP_NAME="managed-ng"

# Current Version

echo "========================================"
echo "Current Cluster Version"
echo "========================================"

aws eks describe-cluster \
    --region "$REGION" \
    --name "$CLUSTER_NAME" \
    --query 'cluster.version' \
    --output text

# Upgrade Control Plane

echo "========================================"
echo "Upgrading Control Plane"
echo "========================================"

aws eks update-cluster-version \
    --region "$REGION" \
    --name "$CLUSTER_NAME" \
    --kubernetes-version "$TARGET_VERSION"

# Wait Until Upgrade Completes

echo "Waiting for Control Plane Upgrade..."

while true
do

STATUS=$(aws eks describe-cluster \
        --region "$REGION" \
        --name "$CLUSTER_NAME" \
        --query 'cluster.status' \
        --output text)

VERSION=$(aws eks describe-cluster \
        --region "$REGION" \
        --name "$CLUSTER_NAME" \
        --query 'cluster.version' \
        --output text)

echo "Status  : $STATUS"
echo "Version : $VERSION"

if [[ "$STATUS" == "ACTIVE" && "$VERSION" == "$TARGET_VERSION" ]]
then
    break
fi

sleep 30

done

# Upgrade Managed Node Group

echo "========================================"
echo "Upgrading Managed Node Group"
echo "========================================"

aws eks update-nodegroup-version \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$NODEGROUP_NAME"

echo "Waiting for Node Group..."

aws eks wait nodegroup-active \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$NODEGROUP_NAME"


# Update VPC CNI

echo "Updating VPC CNI..."

aws eks update-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name vpc-cni \
    --resolve-conflicts OVERWRITE

# Update CoreDNS

echo "Updating CoreDNS..."

aws eks update-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name coredns \
    --resolve-conflicts OVERWRITE

# Update kube-proxy

echo "Updating kube-proxy..."

aws eks update-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name kube-proxy \
    --resolve-conflicts OVERWRITE

# Wait for Addons

echo "Waiting for Addons..."

sleep 60

# Verification

echo
echo "========================================"
echo "Cluster Information"
echo "========================================"

aws eks describe-cluster \
    --region "$REGION" \
    --name "$CLUSTER_NAME" \
    --query 'cluster.version'

echo "========================================"
echo "Nodes"
echo "========================================"

kubectl get nodes -o wide

echo "========================================"
echo "System Pods"
echo "========================================"

kubectl get pods -A

echo "========================================"
echo "Managed Node Groups"
echo "========================================"

aws eks list-nodegroups \
    --cluster-name "$CLUSTER_NAME"

echo "========================================"
echo "Addon Versions"
echo "========================================"

aws eks list-addons \
    --cluster-name "$CLUSTER_NAME"

echo "========================================"
echo "EKS Upgrade Completed Successfully"
echo "========================================"