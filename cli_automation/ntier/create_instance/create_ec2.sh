#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.properties"

# Validate config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: config.properties not found at $CONFIG_FILE" >&2
  exit 1
fi

# Load config
source "$CONFIG_FILE"

# AWS CLI sanity check
command -v aws >/dev/null 2>&1 || {
  echo "ERROR: aws CLI not installed" >&2
  exit 1
}

aws sts get-caller-identity >/dev/null 2>&1 || {
  echo "ERROR: AWS credentials not configured" >&2
  exit 1
}

# REQUIRED VARS
: "${REGION:?Missing REGION}"
: "${INSTANCE_TYPE:?Missing INSTANCE_TYPE}"
: "${KEY_NAME:?Missing KEY_NAME}"
: "${INSTANCE_TAG_NAME:?Missing INSTANCE_TAG_NAME}"
: "${PUBLIC_SUBNET_IDS:?Missing PUBLIC_SUBNET_IDS}"
: "${SG_IDS:?Missing SG_IDS}"
: "${USER_DATA_FILE:?Missing USER_DATA_FILE}"

# AMI_ID may come from ami.sh or config.properties
if [[ -z "${AMI_ID:-}" ]]; then
  echo "ERROR: AMI_ID not set. Run: source ami.sh" >&2
  exit 1
fi

# Normalize user-data path
if [[ ! -f "$USER_DATA_FILE" ]]; then
  USER_DATA_FILE="$SCRIPT_DIR/../$USER_DATA_FILE"
fi

if [[ ! -f "$USER_DATA_FILE" ]]; then
  echo "ERROR: USER_DATA_FILE not found" >&2
  exit 1
fi

# Convert lists to arrays
IFS=' ' read -r -a PUBLIC_SUBNET_ARRAY <<< "$PUBLIC_SUBNET_IDS"
IFS=' ' read -r -a SG_ARRAY <<< "$SG_IDS"

COUNT="${#PUBLIC_SUBNET_ARRAY[@]}"

# Validate counts
if [[ "$COUNT" -eq 0 || "$COUNT" -ne "${#SG_ARRAY[@]}" ]]; then
  echo "ERROR: Subnet and SG counts must match and not be empty" >&2
  exit 1
fi

echo "Using AMI: $AMI_ID" >&2
echo "Creating EC2 Instances..." >&2

INSTANCE_IDS=()

# Create instances
for ((i=0; i<COUNT; i++)); do
  INSTANCE_TAG="${INSTANCE_TAG_NAME}-$((i+1))"

  echo "Creating EC2 in subnet ${PUBLIC_SUBNET_ARRAY[$i]} with SG ${SG_ARRAY[$i]}" >&2

  INSTANCE_ID="$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "${SG_ARRAY[$i]}" \
    --subnet-id "${PUBLIC_SUBNET_ARRAY[$i]}" \
    --user-data "file://$USER_DATA_FILE" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_TAG}}]" \
    --query 'Instances[0].InstanceId' \
    --output text)"

  [[ -n "$INSTANCE_ID" && "$INSTANCE_ID" != "None" ]] || {
    echo "ERROR: Failed to create EC2 instance" >&2
    exit 1
  }

  aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

  echo "EC2 Instance created: $INSTANCE_ID ($INSTANCE_TAG)" >&2
  INSTANCE_IDS+=("$INSTANCE_ID")
done

# EXPORT ONLY (stdout)
echo "export INSTANCE_IDS=\"${INSTANCE_IDS[*]}\""
