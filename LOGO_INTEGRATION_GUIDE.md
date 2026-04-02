# BusNStay Logo Integration

## Overview

The BusNStay Logo.png has been successfully integrated as:
- **App Icon** for Android APK (all screen densities)
- **Splash Screen Icon** for Capacitor
- **PWA Icon** for web app installation
- **Vercel Deployment** configuration included

## Files Updated

### Android Resources
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png          (48x48)
├── mipmap-hdpi/ic_launcher.png          (72x72)
├── mipmap-xhdpi/ic_launcher.png         (96x96)
├── mipmap-xxhdpi/ic_launcher.png        (144x144)
└── mipmap-xxxhdpi/ic_launcher.png       (192x192)
```

### Configuration Files
- `capacitor.config.ts` - Updated splash screen configuration
- `vite.config.ts` - Added logo to PWA manifest
- `vercel.json` - Vercel deployment configuration
- `public/logo.png` - Logo for web assets

### GitHub Actions
- `.github/workflows/build-apk.yml` - Build APK with logo
- `.github/workflows/deploy-vercel.yml` - Deploy to Vercel

## Rebuilding APK with Logo

### Quick Rebuild
```bash
PowerShell -ExecutionPolicy Bypass -File REBUILD_APK_WITH_LOGO.ps1
```

### Manual Steps
```bash
# Build web app
npm run build

# Sync Capacitor
npx cap sync android

# Build APK
cd android
./gradlew assembleDebug
```

APK output: `android/app/build/outputs/apk/debug/app-debug.apk`

## GitHub Deployment

### Setting up GitHub Actions

1. **Enable GitHub Actions** in your repository settings
2. **Workflows included:**
   - `build-apk.yml` - Builds APK on push to main/develop
   - `deploy-vercel.yml` - Deploys web app to Vercel

3. **Triggers:**
   - Push to `main` or `develop` branches
   - Pull requests to `main`
   - Manual trigger via GitHub UI

## Vercel Deployment

### Configuration Files
- `vercel.json` - Main Vercel config
- `railway.json` - Railway deployment (if used)
- `railway.toml` - Railway config (if used)

### Features Enabled
✅ Production builds with cache control  
✅ Security headers (X-Content-Type-Options, X-Frame-Options, etc.)  
✅ Service Worker caching optimization  
✅ Automatic deployments on git push  

### Deploy Manually
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel

# Deploy to production
vercel --prod
```

### Environment Variables
Add these to Vercel dashboard:
- `VITE_APP_NAME=BusNStay - Journey Tracking`
- `VITE_APP_VERSION=1.0.0`
- `SUPABASE_URL=` (your Supabase URL)
- `SUPABASE_ANON_KEY=` (your Supabase anonymous key)

## PNG Icon Specifications

**Logo.png Details:**
- Location: `Logo.png` (root directory)
- Size: 2.1 MB
- Format: PNG with transparency
- Used for: All UI contexts (app icon, splash, PWA)

**Android Icon Implementation:**
- Same PNG copied to all mipmap folders
- Android automatically scales for each density
- Supports all device types

**PWA Icon:**
- `public/logo.png` - 512x512 resolution
- Marked as `maskable` and `any`
- Used for app installation

## CI/CD Pipeline

### Build Process (GitHub Actions)
```
1. Checkout code
2. Setup Node.js 18
3. Setup Java 17
4. Setup Android SDK (API 35)
5. Install npm dependencies
6. Build Vite app (npm run build)
7. Sync Capacitor (npx cap sync android)
8. Build APK (./gradlew assembleDebug)
9. Upload APK as artifact (30 days retention)
```

### Deploy Process (Vercel)
```
1. Checkout code
2. Setup Node.js 18
3. Install npm dependencies
4. Build app (npm run build)
5. Deploy to Vercel
6. Production: main branch
7. Preview: pull requests
```

## Artifacts

### GitHub Artifacts
- APK automatically uploaded on successful build
- Available for download for 30 days
- Can be attached to releases/tags

### Vercel Deployments
- Production URL: Your custom domain / Vercel domain
- Preview URL: Automatically generated for PRs
- Automatic SSL/TLS

## Troubleshooting

### APK Build Fails
```bash
# Clean and rebuild
cd android
rm -rf .gradle build
./gradlew clean assembleDebug
```

### Vercel Deployment Fails
```bash
# Check build logs
vercel logs [project-name]

# Verify environment variables are set
vercel env ls
```

### Icon Not Showing
1. Clear app cache: `adb shell pm clear com.busnstay.app`
2. Reinstall APK: `adb uninstall com.busnstay.app && adb install -r app-debug.apk`
3. Verify ic_launcher.png in all mipmap folders

## Next Steps

1. **Configure GitHub Secrets** (if not done)
   - Add `GITHUB_TOKEN` for releases

2. **Configure Vercel Secrets** (if deploying web)
   - Add `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
   - Add Supabase credentials

3. **Customize Logos** (optional)
   - Create different logo versions for dark/light themes
   - Add adaptive icons for Android 8+
   - Optimize PNG with TinyPNG

4. **Test Installations**
   - Test APK on real device
   - Test web app on Vercel
   - Verify PWA install on mobile

## Resources

- [Capacitor Docs](https://capacitorjs.com/docs)
- [Android App Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [PWA Icons](https://web.dev/add-manifest/)
- [Vercel Deployment](https://vercel.com/docs)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**Status:** ✅ Logo integration complete and ready for deployment

