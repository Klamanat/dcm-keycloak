# Keycloak on Kubernetes

Keycloak 26.5.7 + PostgreSQL 16 บน Kubernetes

## โครงสร้างไฟล์

```
keycloak/
├── namespace.yaml
├── secret.yaml              # Keycloak admin credentials
├── deployment.yaml          # Keycloak deployment
├── service.yaml
├── ingress.yaml             # ใช้สำหรับ production เท่านั้น
├── realm/
│   ├── realm.json
│   └── realm-master.json
└── postgres/
    ├── secret.yaml          # PostgreSQL credentials
    ├── pvc.yaml
    ├── deployment.yaml
    └── service.yaml
```

---

## Run บน Local

### ข้อกำหนด

- Kubernetes cluster (minikube / kind / Docker Desktop)
- `kubectl` ติดตั้งและ config แล้ว

### 1. Apply manifests

```bash
kubectl apply -f namespace.yaml
kubectl apply -f postgres/secret.yaml
kubectl apply -f postgres/pvc.yaml
kubectl apply -f postgres/service.yaml
kubectl apply -f postgres/deployment.yaml
kubectl apply -f secret.yaml
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml
```

### 1.1 สร้าง ConfigMap สำหรับ Realm

Deployment ใช้ `--import-realm` ซึ่ง Keycloak จะอ่านไฟล์จาก ConfigMap `keycloak-realm` ที่ mount ไว้ที่ `/opt/keycloak/data/import`

> **สำคัญ:** ใช้เฉพาะ `realm.json` เท่านั้น — **ห้ามใส่ `realm-master.json`** เพราะจะทำให้ Keycloak crash ตอน startup (`adminRealm is null`)

```bash
# สร้าง ConfigMap ครั้งแรก
kubectl create configmap keycloak-realm \
  --from-file=realm.json=realm/realm.json \
  -n keycloak
```

**อัปเดต ConfigMap เมื่อแก้ไข realm.json:**

```bash
# ลบ ConfigMap เก่าแล้วสร้างใหม่
kubectl delete configmap keycloak-realm -n keycloak
kubectl create configmap keycloak-realm \
  --from-file=realm.json=realm/realm.json \
  -n keycloak

# Restart Keycloak เพื่อ import realm ใหม่
kubectl rollout restart deployment/keycloak -n keycloak
```

**ตรวจสอบ ConfigMap:**

```bash
kubectl get configmap keycloak-realm -n keycloak -o yaml
```

### 2. รอให้ทุก pod พร้อม

```bash
kubectl get pods -n keycloak -w
```

ทุก pod ต้องเป็น `Running` และ `READY 1/1` ก่อนไปขั้นต่อไป

### 3. Port-forward

```bash
kubectl port-forward svc/keycloak 8080:80 -n keycloak
```

### 4. เปิดใน browser

| URL | คำอธิบาย |
|---|---|
| `http://localhost:8080` | Keycloak หน้าหลัก |
| `http://localhost:8080/admin` | Admin Console |

**Default credentials (local):**

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `admin` |

> ดูหรือเปลี่ยน credentials ได้ใน `secret.yaml` (base64 encoded)

---

## Custom Theme & SPI ด้วย Keycloakify

ใช้ [Keycloakify v11](https://www.keycloakify.dev/) สร้าง custom theme ด้วย React และ bundle เป็น JAR เข้า Keycloak ผ่าน Docker image

### 1. สร้าง Keycloakify project

```bash
# scaffold project ใหม่ใน ./theme/
npx keycloakify@latest init theme
cd theme
npm install
```

### 2. พัฒนา theme

```bash
cd theme

# Start Storybook สำหรับ preview หน้า login, register ฯลฯ
npm run storybook

# หรือ test กับ Keycloak จริงผ่าน dev-server
npm run start-keycloak
```

ไฟล์ที่แก้บ่อย:

| ไฟล์ | คำอธิบาย |
|---|---|
| `src/login/` | หน้า Login, Register, Reset password |
| `src/account/` | Account Console (ถ้าต้องการ custom) |
| `src/login/KcPage.tsx` | Entry point ของ theme |

### 3. Build JAR

```bash
cd theme
npx keycloakify build
# ได้ JAR ที่ dist_keycloak/keycloak-theme-*.jar
```

### 4. Build Docker image

```bash
# จาก root directory (ที่มี Dockerfile)
docker build -t keycloak-custom:latest .
```

### 5. Deploy

```bash
# Deployment ใช้ image keycloak-custom:latest + imagePullPolicy: IfNotPresent
# Docker Desktop จะหยิบ image ที่ build ไว้ local ได้เลย
kubectl rollout restart deployment/keycloak -n keycloak
```

### เลือก theme ใน realm

หลัง deploy แล้ว เข้า Admin Console:

```
Realm Settings → Themes → Login Theme → เลือก theme ที่ build
```

---

## ทดสอบ my-realm ผ่าน Account Console

หลัง Keycloak start แล้ว (port-forward อยู่ที่ 8080) สามารถเข้า Account Console ของ `my-realm` ได้เลย

### 1. สร้าง user ทดสอบ

เข้า Admin Console แล้วสร้าง user ใน `my-realm`:

```
http://localhost:8080/admin → เลือก realm "my-realm" → Users → Add user
```

| Field | ค่าตัวอย่าง |
|---|---|
| Username | `testuser` |
| Email | `test@example.com` |
| First name | `Test` |
| Last name | `User` |

หลัง Save ไปที่ tab **Credentials** → Set password → ปิด Temporary

### 2. เข้า Account Console

```
http://localhost:8080/realms/my-realm/account/
```

Login ด้วย user ที่สร้างในขั้นตอนที่ 1

### 3. ทดสอบผ่าน curl (optional)

```bash
# ขอ token ด้วย Resource Owner Password Grant
curl -s -X POST \
  http://localhost:8080/realms/my-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=my-app" \
  -d "username=testuser" \
  -d "password=<password>" | jq .

# เช็ค userinfo ด้วย access_token ที่ได้
curl -s http://localhost:8080/realms/my-realm/protocol/openid-connect/userinfo \
  -H "Authorization: Bearer <access_token>" | jq .
```

> **หมายเหตุ:** `my-app` client ใช้ `directAccessGrantsEnabled: true` จึง support Password Grant ได้โดยไม่ต้องใช้ client secret

---

## Deploy บน Production

### สิ่งที่ต้องแก้ก่อน deploy

**1. ตั้ง hostname จริงใน `deployment.yaml`:**

```yaml
- name: KC_HOSTNAME
  value: "keycloak.example.com"   # เปลี่ยนเป็น domain จริง
- name: KC_HOSTNAME_STRICT
  value: "true"                   # เปิด strict mode
```

**2. ตั้ง hostname และ TLS ใน `ingress.yaml`:**

```yaml
tls:
  - hosts:
      - keycloak.example.com      # เปลี่ยนเป็น domain จริง
    secretName: keycloak-tls      # สร้าง TLS secret ก่อน
rules:
  - host: keycloak.example.com    # เปลี่ยนเป็น domain จริง
```

**3. เปลี่ยน credentials ใน secrets (ห้ามใช้ค่า default ใน prod):**

```bash
# encode ค่าใหม่
echo -n "your-strong-password" | base64
```

แก้ทั้ง `secret.yaml` และ `postgres/secret.yaml`

**4. Apply ingress เพิ่มเติม:**

```bash
kubectl apply -f ingress.yaml
```

### TLS ด้วย cert-manager (แนะนำ)

```bash
# ติดตั้ง cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# สร้าง Certificate resource แยกต่างหาก หรือใช้ annotation บน ingress
```

---

## Troubleshooting

**ดู log Keycloak:**

```bash
kubectl logs -n keycloak -l app=keycloak -f
```

**ดู log PostgreSQL:**

```bash
kubectl logs -n keycloak -l app=postgres -f
```

**เช็ค health:**

```bash
# ผ่าน port-forward management port
kubectl port-forward svc/keycloak 9000:9000 -n keycloak

curl http://localhost:9000/health/ready
curl http://localhost:9000/health/live
```

**ลบทุกอย่างออก:**

```bash
kubectl delete namespace keycloak
```
