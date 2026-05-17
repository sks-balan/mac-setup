#!/bin/bash
# Sets up the Podman C++ dev environment on spear_development SSD.
# Run after bootstrap.sh once the SSD is mounted.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="/Volumes/spear_development/logs/work/sbalan"

if [ ! -d "/Volumes/spear_development" ]; then
  echo "Error: spear_development SSD not mounted."
  exit 1
fi

echo "==> Creating SSD directory structure..."
mkdir -p "$WORK_ROOT/development"
mkdir -p "$WORK_ROOT/docker"
mkdir -p "$WORK_ROOT/podman"
mkdir -p "$WORK_ROOT/tools"

echo "==> Symlinking container storage to SSD..."
mkdir -p "$HOME/.local/share"
if [ -L "$HOME/.local/share/containers" ]; then
  echo "    Symlink already exists, skipping."
elif [ -d "$HOME/.local/share/containers" ]; then
  echo "    WARNING: ~/.local/share/containers exists as a real directory."
  echo "    Move it manually to $WORK_ROOT/podman and re-run."
  exit 1
else
  ln -s "$WORK_ROOT/podman" "$HOME/.local/share/containers"
  echo "    Symlink created."
fi

echo "==> Initialising Podman machine (spear-dev)..."
if podman machine inspect spear-dev &>/dev/null; then
  echo "    Machine already exists, skipping init."
else
  podman machine init --cpus 4 --memory 4096 spear-dev
fi

echo "==> Starting Podman machine..."
if podman machine inspect spear-dev --format '{{.State}}' | grep -q "running"; then
  echo "    Already running."
else
  podman machine start spear-dev
fi

echo "==> Building C++ dev image..."
podman build -t spear-cpp-dev:latest -f "$SCRIPT_DIR/Dockerfile.cpp-dev" "$SCRIPT_DIR"

echo "==> Copying start-dev.sh to tools/..."
cp "$SCRIPT_DIR/../tools/start-dev.sh" "$WORK_ROOT/tools/start-dev.sh" 2>/dev/null || true
chmod +x "$WORK_ROOT/tools/start-dev.sh"

echo ""
echo "Done. Run your dev environment with:"
echo "  $WORK_ROOT/tools/start-dev.sh"
