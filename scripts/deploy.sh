#!/bin/bash
# ============================================================
# deploy.sh — Deploy ไปยัง Kubernetes
# ============================================================
# Usage:
#   ./scripts/deploy.sh dev         Deploy to dev
#   ./scripts/deploy.sh sit         Deploy to sit
#   ./scripts/deploy.sh uat         Deploy to uat
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
  local values_file="k8s/values/$env.yaml"

  if [ ! -f "$values_file" ]; then
    echo "Error: ไม่พบ '$values_file'"
    exit 1
  fi

  echo "▶ Deploying to $env..."
  helm upgrade --install keycloak k8s/chart/ \
    -f "$values_file" \
    --atomic --timeout 5m
  update_realm
  echo ""
  echo "✔ Deployed to $env"
  echo ""
  kubectl get pods -n keycloak
}

# ---- Main ---------------------------------------------------
case "$ENV" in
  dev|sit|uat|prod)
    deploy_env "$ENV"
    ;;
  realm)
    update_realm
    ;;
  *)
    echo "Usage: $0 {dev|sit|uat|prod|realm}"
    exit 1
    ;;
esac
