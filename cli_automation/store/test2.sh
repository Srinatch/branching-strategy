set -euo pipefail

# LOAD CONFIG FILE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.properties.sh"

echo "Using region: $REGION"

# Example usage
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block "$VPC_CIDR" \
  --region "$REGION" \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC created: $VPC_ID"