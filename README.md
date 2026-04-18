# keycloak-dcm

Keycloak 26.5.7 + PostgreSQL บน Kubernetes พร้อม Custom Theme (Keycloakify) และ SPI (Java)

## โครงสร้างไฟล์

```
keycloak-dcm/
├── Dockerfile
├── k8s/
│   ├── namespace.yaml
│   ├── keycloak/
│   │   ├── deployment.yaml          # shared ทุก env (อ่านจาก ConfigMap keycloak-env)
│   │   └── service.yaml
│   ├── postgres/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── envs/
│       ├── local/
│       │   ├── keycloak-env.yaml    # ConfigMap: KC_HOSTNAME=localhost
│       │   ├── keycloak-secret.yaml
│       │   ├── postgres-secret.yaml
│       │   └── postgres-pvc.yaml    # 1Gi
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

## Run บน Local

### ข้อกำหนด

- Docker Desktop พร้อม Kubernetes เปิดอยู่
- `kubectl` ติดตั้งและ config แล้ว

### 1. Apply manifests

```bash
# Shared resources
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/keycloak/

# Local-specific (secrets, ConfigMap, PVC)
kubectl apply -f k8s/envs/local/
```

### 1.1 สร้าง ConfigMap สำหรับ Realm

> **สำคัญ:** ใช้เฉพาะ `realm.json` เท่านั้น — **ห้ามใส่ `realm-master.json`** เพราะจะทำให้ Keycloak crash (`adminRealm is null`)

```bash
# สร้าง ConfigMap ครั้งแรก
kubectl create configmap keycloak-realm \
  --from-file=realm.json=realm/realm.json \
  -n keycloak
```

**อัปเดตเมื่อแก้ไข realm.json:**

```bash
kubectl delete configmap keycloak-realm -n keycloak
kubectl create configmap keycloak-realm \
  --from-file=realm.json=realm/realm.json \
  -n keycloak
kubectl rollout restart deployment/keycloak -n keycloak
```

### 2. รอให้ทุก pod พร้อม

```bash
kubectl get pods -n keycloak -w
```

ทุก pod ต้องเป็น `Running` และ `READY 1/1`

### 3. Port-forward

```bash
kubectl port-forward svc/keycloak 8080:80 -n keycloak
```

### 4. เปิดใน browser

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

```bash
# Log Keycloak
kubectl logs -n keycloak -l app=keycloak -f

# Log PostgreSQL
kubectl logs -n keycloak -l app=postgres -f

# Health check
kubectl port-forward svc/keycloak 9000:9000 -n keycloak
curl http://localhost:9000/health/ready

# ลบทุกอย่าง
kubectl delete namespace keycloak
```
