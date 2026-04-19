# keycloak-dcm

Keycloak 26.5.7 + PostgreSQL บน Kubernetes พร้อม Custom Theme (Keycloakify) และ SPI (Java)

## โครงสร้างไฟล์

```
keycloak-dcm/
├── Dockerfile
├── docker-compose.yml               # Local development
├── k8s/
│   ├── namespace.yaml
│   ├── keycloak/
│   │   ├── deployment.yaml          # shared ทุก env
│   │   └── service.yaml
│   ├── postgres/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── envs/
│       ├── staging/
│       │   ├── keycloak-env.yaml    # ConfigMap: KC_HOSTNAME=staging...
│       │   ├── keycloak-secret.yaml # gitignored
│       │   ├── postgres-secret.yaml # gitignored
│       │   ├── postgres-pvc.yaml    # 5Gi
│       │   └── ingress.yaml
│       └── prod/
│           ├── keycloak-env.yaml    # ConfigMap: KC_HOSTNAME=prod...
│           ├── keycloak-secret.yaml # gitignored
│           ├── postgres-secret.yaml # gitignored
│           ├── postgres-pvc.yaml    # 10Gi
│           └── ingress.yaml
├── realm/
│   └── realm.json
├── theme/                           # Keycloakify v11 (React + Vite)
└── spi/                             # Java SPI (Maven)
```

---

## Scripts

| คำสั่ง | คำอธิบาย |
|---|---|
| `./scripts/dev.sh up` | Start local (Docker Compose + build) |
| `./scripts/dev.sh down` | Stop local |
| `./scripts/dev.sh logs` | ดู Keycloak log |
| `./scripts/dev.sh realm` | Reload realm.json |
| `./scripts/build.sh` | Build image สำหรับ production |
| `./scripts/build.sh 1.2.0` | Build พร้อม tag version |
| `./scripts/deploy.sh staging` | Deploy ไป staging |
| `./scripts/deploy.sh prod` | Deploy ไป production |
| `./scripts/deploy.sh realm` | อัปเดต realm บน K8s |

---

## Build Docker Image

```bash
# Build image รวม theme + SPI
docker build -t keycloak-dcm:latest .
```

> ต้องมี `npm install` ใน `theme/` ก่อน build ครั้งแรก:
> ```bash
> cd theme && npm install
> ```

---

## Run บน Local (Docker Compose)

### ข้อกำหนด

- Docker Desktop

### 1. Start

```bash
# ครั้งแรก หรือเมื่อแก้ theme / SPI → build image ใหม่
docker compose up -d --build

# ครั้งถัดไป (ไม่มีการเปลี่ยน theme/SPI)
docker compose up -d
```

**เมื่อแก้ไข:**

| เปลี่ยนอะไร | คำสั่ง |
|---|---|
| `theme/` (React) | `docker compose up -d --build` |
| `spi/` (Java) | `cd spi && mvn package -DskipTests` แล้ว `docker compose up -d --build` |
| `realm/realm.json` | `docker compose restart keycloak` |

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

## Custom Theme (Keycloakify v11)

```bash
cd theme

# Preview ด้วย Storybook
npm run storybook

# Eject หน้าที่ต้องการ custom
npx keycloakify eject-page
```

| ไฟล์ | คำอธิบาย |
|---|---|
| `theme/src/login/KcPage.tsx` | Router ของ login theme |
| `theme/src/login/i18n.ts` | เพิ่ม/แก้ translation |
| `theme/src/login/KcContext.ts` | Extend KcContext |

หลัง deploy: `Realm Settings → Themes → Login Theme → เลือก theme ที่ build`

---

## Custom SPI (Java)

```bash
cd spi
mvn package -DskipTests
# ได้ target/keycloak-spi-1.0.0.jar
```

| SPI | Interface | ตัวอย่างที่มีอยู่ |
|---|---|---|
| Event Listener | `EventListenerProvider` | `DcmEventListenerProvider` |
| Authenticator | `Authenticator` | — |
| User Storage | `UserStorageProvider` | — |
| REST endpoint | `RealmResourceProvider` | — |
| Token Mapper | `ProtocolMapper` | — |

เปิดใช้ Event Listener: `Realm Settings → Events → Event listeners → dcm-event-listener`

สร้าง SPI ใหม่: implement interface + Factory + ลง `META-INF/services/`

---

## ทดสอบ my-realm ผ่าน Account Console

### สร้าง user ทดสอบ

```
Admin Console → เลือก realm "my-realm" → Users → Add user
```

ไปที่ tab **Credentials** → Set password → ปิด Temporary

### เข้า Account Console

```
http://localhost:8080/realms/my-realm/account/
```

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

## Deploy บน Production

**1. แก้ `k8s/keycloak/deployment.yaml`:**

```yaml
- name: KC_HOSTNAME
  value: "keycloak.example.com"
- name: KC_HOSTNAME_STRICT
  value: "true"
- name: KC_HOSTNAME_PORT   # ลบบรรทัดนี้ออก
```

**2. แก้ `k8s/keycloak/ingress.yaml`:**

```yaml
tls:
  - hosts: [keycloak.example.com]
    secretName: keycloak-tls
rules:
  - host: keycloak.example.com
```

**3. เปลี่ยน credentials ใน secrets:**

```bash
echo -n "your-strong-password" | base64
# แก้ k8s/keycloak/secret.yaml และ k8s/postgres/secret.yaml
```

**4. ตั้งค่า secrets ใน overlay (gitignored):**

```bash
# encode credentials
echo -n "your-admin" | base64
echo -n "your-strong-password" | base64

# แก้ k8s/overlays/prod/keycloak-secret.yaml
# แก้ k8s/overlays/prod/postgres-secret.yaml
```

**5. Apply prod:**

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/keycloak/
kubectl apply -f k8s/envs/prod/
```

### TLS ด้วย cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
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
kubectl logs -n keycloak -l app=postgres -f

# Health check
kubectl port-forward svc/keycloak 9000:9000 -n keycloak
curl http://localhost:9000/health/ready

# ลบทุกอย่าง
kubectl delete namespace keycloak
```
