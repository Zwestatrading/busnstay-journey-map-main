# 📱 Convert to Native Mobile App with Capacitor

## What Capacitor Does

Takes your React + Vite web app and wraps it as:
- ✅ Native iOS app (for App Store)
- ✅ Native Android app (for Google Play)
- ✅ Web version (same codebase)

All from the same React code!

---

## 🚀 Install Capacitor (15 minutes)

### Step 1: Install Capacitor CLI
```bash
cd c:\Users\zwexm\LPSN\busnstay-journey-map-main

npm install -g @capacitor/cli
```

### Step 2: Initialize Capacitor
```bash
npx cap init
```

When prompted:
```
Project name: BusNStay Delivery
Project ID: com.busnstay.delivery
```

This creates:
- `capacitor.config.ts` - Configuration
- `ios/` folder - iOS app
- `android/` folder - Android app

### Step 3: Add iOS and Android
```bash
npm install @capacitor/core @capacitor/app @capacitor/geolocation

npx cap add ios
npx cap add android
```

This downloads the native SDKs (~500MB total).

### Step 4: Build Your Web App
```bash
npm run build
```

This creates the `dist/` folder that gets bundled in the mobile apps.

### Step 5: Add Web Assets to Native Apps
```bash
npx cap copy
```

This copies your built web app (`dist/`) to:
- `ios/App/public/` - iOS bundle
- `android/app/src/main/assets/public/` - Android bundle

---

## 🍎 Deploy to iOS (App Store)

### Step 1: Open iOS Project
```bash
npx cap open ios
```

This opens Xcode. Your project is ready!

### Step 2: Configure in Xcode
1. Select **App** in left sidebar
2. Go to **Signing & Capabilities**
3. Add your Apple Developer account
4. Set Bundle ID: `com.busnstay.delivery`

### Step 3: Update Info.plist (Location Permission)
Xcode should auto-generate `Info.plist`. If not:

Right-click **App** → **Open As** → **Source Code**

Add these lines before `</dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track deliveries in real-time</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to track deliveries in real-time</string>
<key>NSBonjourServices</key>
<array>
  <string>_http._tcp</string>
  <string>_https._tcp</string>
</array>
```

### Step 4: Build & Test
```bash
# In Xcode:
Product → Build (Cmd + B)
# Then:
Product → Run (Cmd + R)
```

This launches the app in simulator or device.

### Step 5: Submit to App Store
1. Create Apple Developer account ($99/year)
2. Create App ID in Apple Developer portal
3. Create provisioning profile
4. In Xcode: Product → Archive
5. Upload via Xcode or Apple Transporter
6. Wait for App Review (2-5 days)

---

## 🤖 Deploy to Android (Google Play)

### Step 1: Open Android Project
```bash
npx cap open android
```

This opens Android Studio.

### Step 2: Configure in Android Studio
1. File → Project Structure
2. Set fields:
   - Package name: `com.busnstay.delivery`
   - Min SDK: 24 (Android 7.0+)
   - Target SDK: 34 (latest)

### Step 3: Add Location Permissions
Edit: `android/app/src/main/AndroidManifest.xml`

After `<application>` tag, add:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### Step 4: Update gradle.properties
Edit: `android/gradle.properties`

```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
```

### Step 5: Build APK/AAB
```bash
# In Android Studio terminal:
./gradlew build

# Or in Gradle menu:
# Build → Build Bundle(s) / APK(s)
```

### Step 6: Test on Device
```bash
adb install app-debug.apk
```

Or run in Android Studio emulator.

### Step 7: Submit to Google Play
1. Create Google Play Developer account ($25 one-time)
2. Sign APK/AAB with release key
3. Upload to Google Play Console
4. Wait for review (usually 1-2 hours)

---

## 📋 Project Structure After Capacitor

```
your-project/
├── src/                          # Your React source (unchanged)
├── dist/                         # Built web app
├── ios/                          # ← iOS native project
│   └── App/                      # Your iOS app
│       ├── App.xcodeproj
│       └── Podfile
├── android/                      # ← Android native project
│   └── app/
│       └── build.gradle
├── capacitor.config.ts           # ← Capacitor config
├── package.json                  # (unchanged)
└── vite.config.ts                # (unchanged)
```

No changes needed to your React code!

---

## 🔄 Development Workflow

After setup, repeat this for each update:

```bash
# 1. Make changes to React code
#    (edit src/*.tsx files)

# 2. Build web version
npm run build

# 3. Copy to native apps
npx cap copy

# 4. Open and rebuild native apps
npx cap open ios    # or android

# 5. Test in simulator/device
#    (in Xcode or Android Studio)
```

Or automate:
```bash
npm run build && npx cap copy && npx cap open ios
```

---

## 🧪 Test GPS on Native Apps

iOS simulator has mock location:
1. Xcode → Debug → Simulate Location → select "Apple Park"
2. Your app should show marker at that location

Android emulator has mock location:
1. Android Studio → Emulator Controls → Location
2. Enter coordinates
3. Your app updates

---

## ⚙️ Capacitor Configuration

Edit: `capacitor.config.ts`

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.busnstay.delivery',
  appName: 'BusNStay Delivery',
  webDir: 'dist',  // Built React app
  
  // Plugins configuration
  plugins: {
    Geolocation: {
      // iOS
      requestPermissionOnInit: true,
      requestWhenInUse: true, // For battery optimization
      
      // Android
      maximumAge: 10000,       // Use cached location
      timeout: 20000,          // 20 second timeout
    },
    CapacitorHttpClient: {
      enabled: true,
    },
  },
  
  // iOS specific
  ios: {
    preferredLanguage: 'en',
  },
  
  // Android specific
  android: {
    buildOptions: {
      keystorePath: 'path/to/keystore.jks',
      keystorePassword: 'password',
      keystoreAlias: 'alias',
      keystoreAliasPassword: 'password',
      releaseType: 'AAB', // Android App Bundle (for Play Store)
    },
  },
};

export default config;
```

---

## 🔌 Using Geolocation Plugin

Your code already uses `navigator.geolocation` which works great with Capacitor!

If you need more control, use Capacitor's geolocation:

```tsx
import { Geolocation } from '@capacitor/geolocation';

// Get current location
const coordinates = await Geolocation.getCurrentPosition({
  enableHighAccuracy: true,
  timeout: 10000,
  maximumAge: 3000
});

console.log(coordinates.coords.latitude);
console.log(coordinates.coords.longitude);

// Watch location (like navigator.geolocation.watchPosition)
const watchId = await Geolocation.watchPosition(
  {
    enableHighAccuracy: true,
    timeout: 10000,
    maximumAge: 0
  },
  (position) => {
    console.log(position.coords.latitude);
  }
);

// Stop watching
await Geolocation.clearWatch({ id: watchId });
```

---

## 🎯 iOS App Store Checklist

- [ ] Apple Developer account created ($99/year)
- [ ] App ID created in Apple Developer portal
- [ ] Privacy policy written (required)
- [ ] App screenshots taken (6+ per device type)
- [ ] Description & keywords written
- [ ] Version number set (1.0.0)
- [ ] Build number set
- [ ] All code signed properly
- [ ] Ran `Product → Archive` in Xcode
- [ ] Uploaded via Xcode or Transporter
- [ ] Submitted for review
- [ ] Add support contact email
- [ ] Icon (1024x1024 PNG) created

---

## 🎯 Google Play Checklist

- [ ] Google Play Developer account ($25 one-time)
- [ ] Privacy policy written (required)
- [ ] Screenshots taken (4.7" and 5.5" phones)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Icon (512x512 PNG)
- [ ] Description & keywords written
- [ ] Version code set (1)
- [ ] Release notes written
- [ ] Signed APK or AAB built
- [ ] Tested APK on real device
- [ ] Uploaded to beta first (optional but recommended)
- [ ] Submitted for review
- [ ] Support contact email added
- [ ] Content rating questionnaire completed

---

## 🚀 Release to Production

### iOS
```bash
# 1. Increment version in Xcode
#    Xcode → App → General → Version: 1.0.1

# 2. Archive
#    Product → Archive

# 3. Validate
#    Right-click archive → Validate App

# 4. Upload
#    Right-click archive → Distribute App
#    Select: App Store Connect
#    Follow steps...

# 5. TestFlight
#    App Store Connect → TestFlight
#    Add testers, send link
#    Gather feedback

# 6. Release
#    App Store Connect → My Apps
#    Select version → Release to App Store
```

### Android
```bash
# 1. Increment version
#    android/app/build.gradle → versionCode += 1

# 2. Build Release APK/AAB
./gradlew bundleRelease

# 3. Sign release APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore my-release-key.jks \
  app-release.aab \
  alias_name

# 4. Upload to Play Store
#    Google Play Console → App releases
#    Upload AAB file

# 5. Internal Testing
#    Add testers, get feedback

# 6. Release
#    Create new version
#    Set release names
#    Click "Release to Production"
```

---

## 💰 App Store Pricing

| Platform | Cost | Annual | Notes |
|----------|------|--------|-------|
| Apple Developer | $99 | N/A | Unlimited apps after paying once |
| Google Play | $25 | N/A | One-time fee, lifetime |
| **Total** | **$124** | One-time | Both platforms cost ~$124 first year |

Additional costs:
- Icon/graphic design (if not DIY): $50-200
- Hosting (Supabase already covers): Included in deployment

---

## 🛠️ Common Issues & Fixes

### GPS Not Working on iOS
**Problem:** Location returns null even after permission
```
Solution:
1. Check Info.plist has location strings
2. Run on real device (simulator may be unreliable)
3. Go to Settings → Privacy → Location → Your App → Always
4. Try again
```

### Android Won't Build
**Problem:** `ANDROID_SDK_ROOT` not found
```bash
# Fix: Set environment variable
$env:ANDROID_SDK_ROOT = 'C:\Users\YourName\AppData\Local\Android\Sdk'

# Or add to gradle.properties
sdk.dir=C:\Users\YourName\AppData\Local\Android\Sdk
```

### App Size Too Large
**Problem:** APK/IPA > 100MB
```
Solutions:
1. Remove unused dependencies: npm prune --production
2. Split assets: Use image compression
3. Use AAB for Android (smaller than APK)
4. Enable Vite's treeshaking in vite.config.ts
```

### White Screen on Launch
**Problem:** App shows blank screen
```
Solutions:
1. Check webDir in capacitor.config.ts points to 'dist'
2. Run: npm run build && npx cap copy
3. Check browser console: Xcode/Android Studio debugger
4. Verify dist/index.html exists
```

---

## 📊 File Size Estimates

| Platform | Size | Notes |
|----------|------|-------|
| iOS IPA | 50-80 MB | Depends on dependencies |
| Android APK | 40-70 MB | Less heavy than iOS usually |
| Android AAB | 30-50 MB | Smaller, recommended for Play Store |

Deliver tracker app alone: ~3-5MB
With Google Maps + Supabase SDK: ~8-12MB
Total with native libraries: 50-80MB (acceptable)

---

## ✅ Success Criteria

After setup and first test:

- [ ] Run `npm run build` without errors
- [ ] Run `npx cap copy` without errors
- [ ] Open iOS in Xcode and build succeeds
- [ ] Open Android in Android Studio and builds
- [ ] App launches in iOS simulator
- [ ] App launches in Android emulator
- [ ] GPS permission prompt appears
- [ ] Location tracking works
- [ ] Map displays correctly
- [ ] No console errors

---

## 📱 What Works in Native Apps

✅ Your React code (100%)
✅ Vite bundling
✅ TypeScript compilation
✅ Tailwind CSS
✅ React hooks
✅ Navigation (React Router)
✅ API calls (Supabase)
✅ Real-time subscriptions
✅ Geolocation
✅ Maps API (Google, Apple native if you add)

❌ Some browser-only APIs (but you don't need them)

---

## 🔗 Quick Links

- Capacitor Docs: https://capacitorjs.com
- iOS Deployment: https://capacitorjs.com/docs/ios
- Android Deployment: https://capacitorjs.com/docs/android
- Apple Developer: https://developer.apple.com
- Google Play: https://play.google.com/console

---

## Timeline to App Stores

| Step | Time |
|------|------|
| Setup Capacitor | 30 min |
| Configure iOS | 1 hour |
| Configure Android | 1 hour |
| First test build | 30 min |
| Beta testing | 1-2 weeks |
| Apple review | 2-5 days |
| Google review | 1-2 hours |
| **Total (no beta)** | **4-5 hours** |

---

**Ready to build?** Run these commands:

```bash
npm install -g @capacitor/cli
npx cap init
npm install @capacitor/core @capacitor/app @capacitor/geolocation
npx cap add ios
npx cap add android
npm run build
npx cap copy
```

Then:
- iOS: `npx cap open ios` → Build in Xcode
- Android: `npx cap open android` → Build in Android Studio
