# keycloak-dcm

Keycloak 26.5.7 + PostgreSQL บน Kubernetes พร้อม Custom Theme (Keycloakify v11) และ SPI (Java)

## โครงสร้างไฟล์

```
keycloak-dcm/
├── Dockerfile
├── docker-compose.yml               # Local development
├── k8s/
│   ├── chart/                       # Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml              # Default values
│   │   └── templates/
│   │       ├── namespace.yaml
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       ├── ingress.yaml
│   │       └── secret.yaml
│   ├── values/
│   │   ├── dev.yaml
│   │   ├── sit.yaml
│   │   ├── uat.yaml
│   │   └── prod.yaml
│   └── ci/
│       └── Jenkinsfile
├── realm/
│   └── realm.json
├── theme/                           # Keycloakify v11 (React + Vite + Tailwind)
│   ├── src/
│   │   ├── login/
│   │   │   ├── KcPage.tsx
│   │   │   ├── KcContext.ts
│   │   │   ├── i18n.ts
│   │   │   ├── KcPageStory.tsx
│   │   │   └── pages/
│   │   │       ├── Login.tsx
│   │   │       └── Login.stories.tsx
│   │   └── index.css
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   └── vite.config.ts
└── spi/                             # Java SPI (Maven)
```

---

## Scripts

| คำสั่ง | คำอธิบาย |
|---|---|
| `./scripts/dev.sh up` | Start local (Docker Compose + build image) |
| `./scripts/dev.sh down` | Stop local |
| `./scripts/dev.sh logs` | ดู Keycloak log |
| `./scripts/dev.sh realm` | Reload realm.json |
| `./scripts/dev.sh spi` | Build SPI JAR แล้ว hot-reload เข้า container |
| `./scripts/dev.sh theme` | Build theme JAR แล้ว hot-reload เข้า container |
| `./scripts/build.sh` | Build image สำหรับ production |
| `./scripts/build.sh 1.2.0` | Build พร้อม tag version |
| `./scripts/deploy.sh dev` | Deploy ไป dev |
| `./scripts/deploy.sh sit` | Deploy ไป sit |
| `./scripts/deploy.sh uat` | Deploy ไป uat |
| `./scripts/deploy.sh prod` | Deploy ไป production |
| `./scripts/deploy.sh realm` | อัปเดต realm บน K8s |

---

## Run บน Local (Docker Compose)

### ข้อกำหนด

- Docker Desktop

### 1. Start

```bash
# ครั้งแรก หรือเมื่อแก้ theme / SPI → build image ใหม่
./scripts/dev.sh up

# ครั้งถัดไป (ไม่มีการเปลี่ยน theme/SPI)
docker compose up -d
```

### 2. เปิดใน browser

| URL | คำอธิบาย |
|---|---|
| `http://localhost:8080/admin` | Admin Console |
| `http://localhost:8080/realms/my-realm/account/` | Account Console |

**Default credentials (local):**

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `admin` |

---

## Local Development (Hot Reload)

### Theme (Keycloakify)

**วิธีที่ 1 — Storybook** (เร็วที่สุด, ไม่ต้องมี Keycloak)

```bash
cd theme && yarn storybook
# เปิด http://localhost:6006
```

**วิธีที่ 2 — ดูใน Keycloak จริง พร้อม HMR** (ต้องมี Java ติดตั้งในเครื่อง)

```bash
cd theme && yarn start-keycloak
```

**วิธีที่ 3 — Hot-reload เข้า container ที่รันอยู่**

```bash
./scripts/dev.sh theme
# build theme JAR → copy เข้า container → restart keycloak (~30s)
```

### SPI (Java)

ต้องมี Maven ติดตั้งในเครื่อง

```bash
./scripts/dev.sh spi
# mvn package → copy JAR เข้า container → restart keycloak (~10s)
```

### สรุป workflow

| แก้อะไร | คำสั่ง | เวลา |
|---|---|---|
| Theme UI (ดูใน Storybook) | `cd theme && yarn storybook` | HMR ทันที |
| Theme UI (ดูใน Keycloak จริง) | `cd theme && yarn start-keycloak` | HMR ทันที |
| Theme → test ใน Keycloak local | `./scripts/dev.sh theme` | ~30 วิ |
| SPI | `./scripts/dev.sh spi` | ~10 วิ |
| แก้ทั้ง theme + SPI พร้อมกัน | `./scripts/dev.sh up` | rebuild image |

---

## Custom Theme (Keycloakify v11 + Tailwind CSS)

ดูรายละเอียดทั้งหมดใน [theme/README.md](theme/README.md)

```bash
cd theme && yarn build-keycloak-theme
```

---

## Custom SPI (Java)

ดูรายละเอียดทั้งหมดใน [spi/README.md](spi/README.md)

```bash
cd spi && mvn package -DskipTests
```

---

## Build Docker Image (Production)

```bash
./scripts/build.sh          # tag: keycloak-dcm:latest
./scripts/build.sh 1.2.0    # tag: keycloak-dcm:1.2.0
```

---

## CI/CD (Jenkins)

Jenkinsfile อยู่ที่ `k8s/ci/Jenkinsfile`

### ตั้งค่า Jenkins Job

1. สร้าง Pipeline job
2. ตั้ง **Script Path** เป็น `k8s/ci/Jenkinsfile`

### Branch Strategy

| Branch | Action |
|---|---|
| `dev` | build → push → deploy **dev** |
| `sit` | build → push → deploy **sit** |
| `uat` | build → push → deploy **uat** |
| `main` | build → push → deploy **prod** |
| อื่นๆ | build → push เท่านั้น |

### Jenkins Credentials

| Credential ID | Type | ค่า |
|---|---|---|
| `REGISTRY_URL` | Secret text | URL ของ container registry |
| `registry-credentials` | Username/Password | login registry |
| `kubeconfig-dev` | Secret file | kubeconfig สำหรับ dev cluster |
| `kubeconfig-sit` | Secret file | kubeconfig สำหรับ sit cluster |
| `kubeconfig-uat` | Secret file | kubeconfig สำหรับ uat cluster |
| `kubeconfig-prod` | Secret file | kubeconfig สำหรับ prod cluster |
| `keycloak-admin-user-<env>` | Secret text | Keycloak admin username |
| `keycloak-admin-pass-<env>` | Secret text | Keycloak admin password |
| `keycloak-db-url-<env>` | Secret text | JDBC URL ของ database |
| `keycloak-db-username-<env>` | Secret text | Database username |
| `keycloak-db-password-<env>` | Secret text | Database password |

---

## Deploy บน Kubernetes (Helm)

### ข้อกำหนด

- `helm` และ `kubectl` ติดตั้งในเครื่อง
- kubeconfig ชี้ไปยัง cluster ที่ต้องการ

### Deploy

```bash
# Deploy พร้อมกำหนด secrets
helm upgrade --install keycloak k8s/chart/ \
  -f k8s/values/prod.yaml \
  --set secret.adminUser=admin \
  --set secret.adminPassword=<password> \
  --set secret.dbUrl=jdbc:postgresql://<host>:5432/keycloak \
  --set secret.dbUsername=<user> \
  --set secret.dbPassword=<password>
```

### Preview ก่อน deploy

```bash
helm template keycloak k8s/chart/ -f k8s/values/prod.yaml
```

### Env values

| File | Replicas | Resources |
|---|---|---|
| `values/dev.yaml` | 1 | cpu: 250m–1, mem: 256Mi–512Mi |
| `values/sit.yaml` | 1 | cpu: 250m–1, mem: 256Mi–512Mi |
| `values/uat.yaml` | 2 | cpu: 500m–2, mem: 512Mi–1Gi |
| `values/prod.yaml` | 3 | cpu: 1–4, mem: 1Gi–2Gi |

### อัปเดต Realm

```bash
./scripts/deploy.sh realm
```

---

## ทดสอบ my-realm ผ่าน Account Console

### สร้าง user ทดสอบ

```
Admin Console → เลือก realm "my-realm" → Users → Add user
```

ไปที่ tab **Credentials** → Set password → ปิด Temporary

### ทดสอบด้วย curl

```bash
# ขอ token
curl -s -X POST \
  http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=my-app&username=testuser&password=<password>" | jq .

# เช็ค userinfo
curl -s http://localhost:8080/realms/my-realm/protocol/openid-connect/userinfo \
  -H "Authorization: Bearer <access_token>" | jq .
```

---

## Troubleshooting

**Local (Docker Compose):**

```bash
# Log
docker compose logs keycloak -f
docker compose logs postgres -f

# Restart
docker compose restart keycloak

# ลบทุกอย่าง (รวม volume)
docker compose down -v
```

**Staging / Prod (Kubernetes):**

```bash
# Log
kubectl logs -n keycloak -l app=keycloak -f

# Health check
kubectl port-forward svc/keycloak 9000:9000 -n keycloak
curl http://localhost:9000/health/ready

# Helm rollback
helm rollback keycloak -n keycloak

# ลบทุกอย่าง
helm uninstall keycloak -n keycloak
kubectl delete namespace keycloak
```
