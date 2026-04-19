#!/bin/bash
# ============================================================
# build.sh — Build Docker image สำหรับ production
# ============================================================
# Usage:
#   ./scripts/build.sh              Build image tag: keycloak-dcm:latest
#   ./scripts/build.sh 1.2.0        Build image tag: keycloak-dcm:1.2.0
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

TAG="${1:-latest}"
IMAGE="keycloak-dcm:$TAG"

echo "▶ Building $IMAGE (production — KC_BUILD=true)..."
docker build \
  --build-arg KC_BUILD=true \
  -t "$IMAGE" \
  .

echo ""
echo "✔ Build complete: $IMAGE"
echo ""
echo "Push to registry:"
echo "  docker tag $IMAGE <registry>/$IMAGE"
echo "  docker push <registry>/$IMAGE"
