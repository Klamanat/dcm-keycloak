# ==============================================================
# Stage 1: Build Keycloakify theme (React → JAR)
# ==============================================================
FROM node:20-alpine AS theme-builder

WORKDIR /app

COPY theme/package*.json ./
RUN npm ci

COPY theme/ .

# tsc + vite build + keycloakify build → dist_keycloak/*.jar
RUN npm run build-keycloak-theme

# ==============================================================
# Stage 2: Build SPI (Java Maven → JAR)
# ==============================================================
FROM maven:3.9-eclipse-temurin-21 AS spi-builder

WORKDIR /app

COPY spi/pom.xml .
# Download dependencies ก่อน (cache layer)
RUN mvn dependency:go-offline -q

COPY spi/src ./src

# Build SPI JAR
RUN mvn package -DskipTests -q

# ==============================================================
# Stage 3: Pre-build Keycloak พร้อม providers ทั้งหมด
# ==============================================================
FROM quay.io/keycloak/keycloak:26.5.7 AS keycloak-builder

# Copy theme JAR (Keycloakify)
COPY --from=theme-builder /app/dist_keycloak/*.jar /opt/keycloak/providers/

# Copy SPI JAR
COPY --from=spi-builder /app/target/keycloak-spi-*.jar /opt/keycloak/providers/

# Pre-build Keycloak เพื่อ register providers (ลด startup time + --optimized)
RUN /opt/keycloak/bin/kc.sh build

# ==============================================================
# Final image
# ==============================================================
FROM quay.io/keycloak/keycloak:26.5.7

# Copy Keycloak ที่ pre-built แล้ว (รวม providers ที่ register ไว้)
COPY --from=keycloak-builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
