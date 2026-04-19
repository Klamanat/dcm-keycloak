# ==============================================================
# Stage 1: Build Keycloakify theme (React → JAR)
# ==============================================================
FROM node:20 AS theme-builder

# keycloakify build ต้องการ Maven เพื่อสร้าง JAR
RUN apt-get update -qq && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY theme/package.json theme/yarn.lock ./
RUN yarn install

COPY theme/ .

# tsc + vite build + keycloakify build → dist_keycloak/*.jar
RUN yarn build-keycloak-theme

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
# Stage 3: Keycloak + providers
# ==============================================================
FROM quay.io/keycloak/keycloak:26.5.7 AS keycloak-builder

# Copy theme JAR (Keycloakify)
COPY --from=theme-builder /app/dist_keycloak/*.jar /opt/keycloak/providers/

# Copy SPI JAR
COPY --from=spi-builder /app/target/keycloak-spi-*.jar /opt/keycloak/providers/

# KC_BUILD=true  → production: pre-build เพื่อใช้ start --optimized
# KC_BUILD=false → local dev:  ข้ามขั้นตอนนี้ เพราะ start-dev โหลด providers เองได้
ARG KC_BUILD=true
RUN if [ "$KC_BUILD" = "true" ]; then /opt/keycloak/bin/kc.sh build; fi

# ==============================================================
# Final image
# ==============================================================
FROM quay.io/keycloak/keycloak:26.5.7

# Copy Keycloak ที่ pre-built แล้ว (รวม providers ที่ register ไว้)
COPY --from=keycloak-builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
