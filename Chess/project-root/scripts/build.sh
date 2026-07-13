#!/bin/bash
set -ex

source scripts/common.sh

echo "Building app..."

python3 -m pip install --upgrade pip
pip3 install -r app/requirements.txt