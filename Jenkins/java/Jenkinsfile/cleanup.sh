#!/bin/bash

echo "Cleaning workspace due to failure..."

# Remove build artifacts
rm -rf target/

# Remove downloaded maven
sudo rm -rf /opt/maven

echo "Cleanup completed."