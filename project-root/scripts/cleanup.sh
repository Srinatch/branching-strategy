#!/bin/bash

echo "❌ ERROR detected! Cleaning up resources..."

cd terraform

terraform destroy -auto-approve || true

echo "Cleanup completed 🧹"