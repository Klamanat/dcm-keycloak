# dcm-theme

Custom Keycloak login theme สำหรับ DCM — สร้างด้วย Keycloakify v11 + React + Tailwind CSS

## Stack

- [Keycloakify v11](https://keycloakify.dev) — React → Keycloak JAR
- React 18 + TypeScript + Vite
- Tailwind CSS v3
- Storybook v8

## โครงสร้าง

```
theme/
├── src/
│   ├── login/
│   │   ├── KcPage.tsx           # Router — เลือก component ตาม pageId
│   │   ├── KcContext.ts         # Extend KcContext (custom properties)
│   │   ├── i18n.ts              # Translation
│   │   ├── KcPageStory.tsx      # Storybook helper
│   │   └── pages/
│   │       ├── Login.tsx        # Custom login page (Tailwind)
│   │       └── Login.stories.tsx
│   └── index.css                # Tailwind directives
├── tailwind.config.js
├── postcss.config.js
├── vite.config.ts               # Keycloakify plugin (themeName: dcm-theme)
└── package.json
```

## Development

### Storybook (เร็วที่สุด)

```bash
yarn storybook
# เปิด http://localhost:6006
```

### ดูใน Keycloak จริง พร้อม HMR

ต้องมี Java ติดตั้งในเครื่อง

```bash
yarn start-keycloak
```

Keycloakify จะ download Keycloak และ proxy theme จาก Vite dev server อัตโนมัติ

## เพิ่มหน้าใหม่

**1. สร้าง component** ใน `src/login/pages/`

```tsx
// src/login/pages/Register.tsx
import type { PageProps } from "keycloakify/login/pages/PageProps";

export default function Register(props: PageProps<...>) {
    const { kcContext, i18n } = props;
    return ( /* Tailwind JSX */ );
}
```

**2. Register ใน `KcPage.tsx`**

```tsx
import Register from "./pages/Register";

case "register.ftl":
    return <Register kcContext={kcContext} i18n={i18n} ... />;
```

**3. สร้าง Story**

```tsx
// src/login/pages/Register.stories.tsx
const { KcPageStory } = createKcPageStory({ pageId: "register.ftl" });
export const Default: Story = { args: {} };
```

ดู pageId ทั้งหมดที่รองรับ: [Keycloakify Docs](https://docs.keycloakify.dev/v/v11/keycloak-pages)

## Build

ต้องมี Maven ติดตั้งในเครื่อง (keycloakify ใช้สร้าง JAR)

- macOS: `brew install maven`
- Ubuntu: `sudo apt-get install maven`
- Windows: `choco install maven`

```bash
yarn build-keycloak-theme
# ได้ dist_keycloak/dcm-theme-*.jar
```

## Deploy

หลัง deploy image ไปยัง Keycloak แล้ว เลือก theme ที่:

```
Realm Settings → Themes → Login Theme → dcm-theme
```
