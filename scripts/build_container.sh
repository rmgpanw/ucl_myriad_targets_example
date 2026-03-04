#!/bin/bash
# Build Docker image and convert to Singularity SIF
set -euo pipefail

IMAGE_NAME="ucl_myriad_targets_example"
SIF_NAME="${IMAGE_NAME}.sif"

echo "=== Building Docker image ==="
docker build -t "${IMAGE_NAME}" .

echo "=== Converting to Singularity SIF ==="
# Requires singularity installed locally, or do this step on MYRIAD
singularity build "${SIF_NAME}" "docker-daemon://${IMAGE_NAME}:latest"

echo "=== Done ==="
echo "SIF file: ${SIF_NAME}"
echo "Upload to MYRIAD: scp ${SIF_NAME} myriad:~/Scratch/${IMAGE_NAME}/"
