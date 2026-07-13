#!/bin/bash
set -e

echo "Building application..."

cd app

python3 -m pip install -r requirements.txt

echo "Build successful ✅"