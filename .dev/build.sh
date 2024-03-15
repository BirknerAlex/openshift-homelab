#!/bin/bash

echo "Building the container image"
cd docker/

# Build the container image
docker build --platform linux/amd64 -t tyrola/openshift-homelab:latest .
