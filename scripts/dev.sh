#!/bin/bash
# ============================================================
# dev.sh — Local development (Docker Compose)
# ============================================================
# Usage:
#   ./scripts/dev.sh up       Start (build if needed)
#   ./scripts/dev.sh down     Stop และลบ container
#   ./scripts/dev.sh restart  Restart keycloak
#   ./scripts/dev.sh logs     ดู log แบบ follow
#   ./scripts/dev.sh realm    อัปเดต realm.json แล้ว restart
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

CMD="${1:-up}"

case "$CMD" in
  up)
    echo "▶ Starting local environment..."
    docker compose up -d --build
    echo ""
    echo "✔ Keycloak: http://localhost:8080"
    echo "✔ Admin:    http://localhost:8080/admin  (admin / admin)"
    echo "✔ Account:  http://localhost:8080/realms/my-realm/account/"
    ;;

  down)
    echo "▶ Stopping local environment..."
    docker compose down
    echo "✔ Done"
    ;;

  restart)
    echo "▶ Restarting keycloak..."
    docker compose restart keycloak
    echo "✔ Done"
    ;;

  logs)
    docker compose logs keycloak -f
    ;;

  realm)
    echo "▶ Restarting keycloak to reload realm.json..."
    docker compose restart keycloak
    echo "✔ Done — realm.json reloaded"
    ;;

  *)
    echo "Usage: $0 {up|down|restart|logs|realm}"
    exit 1
    ;;
esac
