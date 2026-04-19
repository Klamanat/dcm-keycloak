# keycloak-spi

Java SPI (Service Provider Interface) สำหรับ Keycloak 26.5.7

## โครงสร้าง

```
spi/
├── pom.xml
└── src/main/
    ├── java/com/dcm/keycloak/
    │   └── event/
    │       ├── DcmEventListenerProvider.java
    │       └── DcmEventListenerProviderFactory.java
    └── resources/META-INF/services/
        └── org.keycloak.events.EventListenerProviderFactory
```

## SPI ที่มีอยู่

### DcmEventListenerProvider

รับ event จาก Keycloak แล้ว log ออกมา

| Event | Log Level | ข้อมูลที่ log |
|---|---|---|
| `LOGIN` | INFO | userId, realm, clientId, ip |
| `LOGIN_ERROR` | WARN | error, realm, ip |
| `LOGOUT` | INFO | userId, realm |
| Admin events | DEBUG | operation, resourceType, realm |

**เปิดใช้งาน:**
```
Realm Settings → Events → Event listeners → เพิ่ม dcm-event-listener
```

## Build

```bash
mvn package -DskipTests
# ได้ target/keycloak-spi-1.0.0.jar
```

## เพิ่ม SPI ใหม่

### 1. สร้าง Provider + Factory

```java
// implement interface ที่ต้องการ
public class MyProvider implements EventListenerProvider { ... }
public class MyProviderFactory implements EventListenerProviderFactory { ... }
```

| SPI | Interface |
|---|---|
| Event Listener | `EventListenerProvider` |
| Authenticator | `Authenticator` |
| User Storage | `UserStorageProvider` |
| REST endpoint | `RealmResourceProvider` |
| Token Mapper | `ProtocolMapper` |

### 2. Register ใน META-INF/services

สร้างไฟล์ `src/main/resources/META-INF/services/<interface-fqcn>` แล้วใส่ชื่อ Factory class:

```
com.dcm.keycloak.MyProviderFactory
```

### 3. Deploy

```bash
# Local (hot-reload)
cd .. && ./scripts/dev.sh spi

# Production → Jenkins build pipeline จัดการให้อัตโนมัติ
```
