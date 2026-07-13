#!/bin/bash
set -e

echo "Checking required tools..."

command -v python3 >/dev/null 2>&1 || { echo "Python3 NOT installed"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker NOT installed"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform NOT installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl NOT installed"; exit 1; }

echo "All required tools are installed ✅"