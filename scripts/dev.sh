#!/bin/bash
# ============================================================
# dev.sh — Local development (Docker Compose)
# ============================================================
# Usage:
#   ./scripts/dev.sh up           Start (build if needed)
#   ./scripts/dev.sh down         Stop และลบ container
#   ./scripts/dev.sh restart      Restart keycloak
#   ./scripts/dev.sh logs         ดู log แบบ follow
#   ./scripts/dev.sh realm        อัปเดต realm.json แล้ว restart
#   ./scripts/dev.sh spi          Build SPI JAR แล้ว hot-reload เข้า container
#   ./scripts/dev.sh theme        Build theme JAR แล้ว hot-reload เข้า container
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

  spi)
    echo "▶ Building SPI JAR..."
    cd spi && mvn package -DskipTests -q && cd "$ROOT_DIR"

    echo "▶ Copying JAR into container..."
    JAR=$(ls spi/target/keycloak-spi-*.jar 2>/dev/null | head -1)
    if [ -z "$JAR" ]; then
      echo "Error: ไม่พบ JAR ใน spi/target/"
      exit 1
    fi
    docker compose cp "$JAR" keycloak:/opt/keycloak/providers/

    echo "▶ Restarting keycloak..."
    docker compose restart keycloak
    echo "✔ SPI reloaded"
    ;;

  theme)
    echo "▶ Building theme JAR (requires Maven locally)..."
    cd theme && yarn build-keycloak-theme && cd "$ROOT_DIR"

    echo "▶ Copying JARs into container..."
    for jar in theme/dist_keycloak/*.jar; do
      docker compose cp "$jar" keycloak:/opt/keycloak/providers/
    done

    echo "▶ Restarting keycloak..."
    docker compose restart keycloak
    echo "✔ Theme reloaded"
    ;;

  *)
    echo "Usage: $0 {up|down|restart|logs|realm|spi|theme}"
    exit 1
    ;;
esac
