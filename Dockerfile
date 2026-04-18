# ==============================================================
# Stage 1: Build Keycloakify theme
# ==============================================================
FROM node:20-alpine AS theme-builder

WORKDIR /app

# สร้าง Keycloakify project ก่อน: npx keycloakify@latest init
# แล้ว copy source มาวางไว้ใน ./theme/
COPY theme/package*.json ./
RUN npm ci

COPY theme/ .

# tsc + vite build + keycloakify build → ได้ JAR ที่ dist_keycloak/
RUN npm run build-keycloak-theme

# ==============================================================
# Stage 2: Pre-build Keycloak พร้อม providers
# ==============================================================
FROM quay.io/keycloak/keycloak:26.5.7 AS keycloak-builder

# Copy theme JAR จาก stage 1
COPY --from=theme-builder /app/dist_keycloak/*.jar /opt/keycloak/providers/

# Pre-build Keycloak เพื่อ register providers (ลด startup time + --optimized)
RUN /opt/keycloak/bin/kc.sh build

# ==============================================================
# Final image
# ==============================================================
FROM quay.io/keycloak/keycloak:26.5.7

# Copy Keycloak ที่ pre-built แล้ว (รวม providers ที่ register ไว้)
COPY --from=keycloak-builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
