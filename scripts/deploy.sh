#!/bin/bash
# ============================================================
# deploy.sh — Deploy ไปยัง Kubernetes
# ============================================================
# Usage:
#   ./scripts/deploy.sh staging     Deploy to staging
#   ./scripts/deploy.sh prod        Deploy to production
#   ./scripts/deploy.sh realm       อัปเดต ConfigMap realm เท่านั้น
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

ENV="${1:-}"

if [ -z "$ENV" ]; then
  echo "Usage: $0 {staging|prod|realm}"
  exit 1
fi

# ---- Realm ConfigMap ----------------------------------------
update_realm() {
  echo "▶ Updating keycloak-realm ConfigMap..."
  kubectl delete configmap keycloak-realm -n keycloak --ignore-not-found
  kubectl create configmap keycloak-realm \
    --from-file=realm.json=realm/realm.json \
    -n keycloak
  echo "▶ Restarting keycloak deployment..."
  kubectl rollout restart deployment/keycloak -n keycloak
  kubectl rollout status deployment/keycloak -n keycloak
  echo "✔ Realm updated"
}

# ---- Apply K8s manifests ------------------------------------
deploy_env() {
  local env="$1"
  local env_dir="k8s/envs/$env"

  if [ ! -d "$env_dir" ]; then
    echo "Error: directory '$env_dir' not found"
    exit 1
  fi

  # ตรวจสอบ secret files ยังมี REPLACE_BASE64 อยู่ไหม
  if grep -r "REPLACE_BASE64" "$env_dir" --include="*.yaml" -q 2>/dev/null; then
    echo "Error: พบ REPLACE_BASE64 ใน $env_dir — กรุณาแก้ secret ก่อน deploy"
    echo ""
    grep -r "REPLACE_BASE64" "$env_dir" --include="*.yaml" -l
    exit 1
  fi

  echo "▶ Deploying to $env..."
  kubectl apply -f k8s/namespace.yaml
  kubectl apply -f k8s/postgres/
  kubectl apply -f k8s/keycloak/
  kubectl apply -f "$env_dir/"
  update_realm
  echo ""
  echo "✔ Deployed to $env"
  echo ""
  kubectl get pods -n keycloak
}

# ---- Main ---------------------------------------------------
case "$ENV" in
  staging|prod)
    deploy_env "$ENV"
    ;;
  realm)
    update_realm
    ;;
  *)
    echo "Usage: $0 {staging|prod|realm}"
    exit 1
    ;;
esac
