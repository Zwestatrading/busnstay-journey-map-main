# QUICK BUILD REFERENCE

## Build APK with New Components

### 🚀 Quick Build (3 Commands)

```bash
npm run build
npx cap sync android
npx cap build android
```

### ⚡ One-Liner
```bash
npm run build && npx cap sync android && npx cap build android
```

### 🤖 Automated (Recommended)
```powershell
PowerShell -ExecutionPolicy Bypass -File BUILD_APK_AUTOMATED.ps1
```

---

## What's Included

| Feature | File | Status |
|---------|------|--------|
| Advanced Forms | `FormFields.tsx` | ✓ Included |
| Accessibility | `useAccessibility.ts` | ✓ Included |
| Mobile Nav | `MobileNav.tsx` | ✓ Included |
| Charts | `DataVisualization.tsx` | ✓ Included |
| Animations | `animationVariants.ts` | ✓ Included |
| Error Handling | `ErrorBoundary.tsx` | ✓ Included |
| Admin Tools | `AdminTools.tsx` | ✓ Included |
| Profile System | `UserProfile.tsx` | ✓ Included |

---

## Output Location

**APK File:** `android/app/build/outputs/apk/debug/app-debug.apk`

Size: ~25-40 MB

---

## Install on Device

```bash
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

---

## Build Time

- **Vite:** 5-30s
- **Sync:** 5-10s  
- **Gradle:** 30-120s
- **Total:** 1-3 minutes

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| npm not found | Install [Node.js](https://nodejs.org) |
| Gradle fails | Delete `android/.gradle` and retry |
| TypeScript errors | Run `npm ci` then `npm run build` |
| Capacitor sync fails | Delete `android/app/src/main/assets/public` |

---

## Release Build

```bash
npm run build
npx cap sync android
npx cap build android --release
```

Located at: `android/app/build/outputs/apk/release/app-release.apk`

---

**Status:** ✓ All 8 components ready for APK inclusion!
