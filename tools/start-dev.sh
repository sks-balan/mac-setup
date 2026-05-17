#!/bin/bash
set -e

WORK_ROOT="/Volumes/spear_development/logs/work/sbalan"
DEV_DIR="$WORK_ROOT/development"

# Check SSD is mounted
if [ ! -d "$WORK_ROOT" ]; then
  echo "Error: spear_development SSD not mounted. Please attach the drive first."
  exit 1
fi

# Start Podman machine if not running
if ! podman machine inspect spear-dev --format '{{.State}}' 2>/dev/null | grep -q "running"; then
  echo "Starting Podman machine..."
  podman machine start spear-dev
fi

echo "Entering C++ dev environment..."
podman run -it --rm \
  -v "$DEV_DIR":/logs/work/sbalan/development \
  --workdir /logs/work/sbalan/development \
  --hostname spear-dev \
  spear-cpp-dev:latest bash
