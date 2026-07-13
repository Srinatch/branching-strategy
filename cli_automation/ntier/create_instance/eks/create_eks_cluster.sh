#!/usr/bin/env bash
set -euo pipefail

# Amazon EKS Cluster Creation Script

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.properties"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: config.properties not found"
    exit 1
fi

source "$CONFIG_FILE"

# Validation


command -v aws >/dev/null 2>&1 || {
    echo "AWS CLI not installed"
    exit 1
}

command -v eksctl >/dev/null 2>&1 || {
    echo "eksctl not installed"
    exit 1
}

command -v kubectl >/dev/null 2>&1 || {
    echo "kubectl not installed"
    exit 1
}

aws sts get-caller-identity >/dev/null

: "${REGION:?Missing REGION}"
: "${VPC_IDS:?Run create.sh first}"
: "${PRIVATE_SUBNET_IDS:?Run create.sh first}"
: "${PUBLIC_SUBNET_IDS:?Run create.sh first}"
: "${KEY_NAME:?Missing KEY_NAME}"


# Variables

CLUSTER_NAME="ntier-eks"

KUBERNETES_VERSION="1.34"

NODEGROUP_NAME="managed-ng"

NODE_INSTANCE_TYPE="t3.medium"

DESIRED_NODES=2
MIN_NODES=2
MAX_NODES=4

# Convert exported strings to arrays

IFS=' ' read -ra VPCS <<< "$VPC_IDS"
IFS=' ' read -ra PRIVATE_SUBNETS <<< "$PRIVATE_SUBNET_IDS"
IFS=' ' read -ra PUBLIC_SUBNETS <<< "$PUBLIC_SUBNET_IDS"

VPC_ID="${VPCS[0]}"

# Need minimum two private subnets

if [[ ${#PRIVATE_SUBNETS[@]} -lt 2 ]]; then
    echo "ERROR: EKS requires at least two private subnets."
    exit 1
fi

# Generate Cluster YAML

cat > cluster.yaml <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${REGION}
  version: "${KUBERNETES_VERSION}"

vpc:
  id: ${VPC_ID}

  subnets:

    private:

      private-1:
        id: ${PRIVATE_SUBNETS[0]}

      private-2:
        id: ${PRIVATE_SUBNETS[1]}

    public:

      public-1:
        id: ${PUBLIC_SUBNETS[0]}

      public-2:
        id: ${PUBLIC_SUBNETS[1]}

managedNodeGroups:

- name: ${NODEGROUP_NAME}

  instanceType: ${NODE_INSTANCE_TYPE}

  desiredCapacity: ${DESIRED_NODES}

  minSize: ${MIN_NODES}

  maxSize: ${MAX_NODES}

  volumeSize: 20

  privateNetworking: true

  ssh:
    allow: true
    publicKeyName: ${KEY_NAME}

addons:

- name: vpc-cni

- name: kube-proxy

- name: coredns
EOF

# Display Configuration

echo "====================================="
echo "Region          : $REGION"
echo "Cluster         : $CLUSTER_NAME"
echo "Version         : $KUBERNETES_VERSION"
echo "VPC             : $VPC_ID"
echo "Private Subnet1 : ${PRIVATE_SUBNETS[0]}"
echo "Private Subnet2 : ${PRIVATE_SUBNETS[1]}"
echo "Public Subnet1  : ${PUBLIC_SUBNETS[0]}"
echo "Public Subnet2  : ${PUBLIC_SUBNETS[1]}"
echo "====================================="

# Create Cluster

echo "Creating Amazon EKS Cluster..."

eksctl create cluster -f cluster.yaml

# Configure kubectl

echo "Updating kubeconfig..."

aws eks update-kubeconfig \
    --region "$REGION" \
    --name "$CLUSTER_NAME"

# Verify

echo "Waiting for cluster..."

aws eks wait cluster-active \
    --region "$REGION" \
    --name "$CLUSTER_NAME"

echo

kubectl get nodes -o wide

echo =========================

kubectl get pods -A

echo ==========================

aws eks describe-cluster \
    --region "$REGION" \
    --name "$CLUSTER_NAME" \
    --query 'cluster.version'

echo "====================================="
echo "EKS Cluster Created Successfully"
echo "====================================="