#!/usr/bin/env bash
set -euo pipefail

if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" >/dev/null 2>&1; then
  aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$KEY_NAME.pem"
  chmod 400 "$KEY_NAME.pem"
fi
