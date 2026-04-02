# BusNStay App - Feature Test Checklist
**Build Date:** 2026-02-24 @ 15:58  
**APK Version:** 5.06 MB (Latest)

---

## 🔙 BACK NAVIGATION (HIGH PRIORITY)

### Hardware Back Button
- [ ] Navigate to **Demo Rider** dashboard
- [ ] Press Android **Hardware Back Button**
- [ ] **Expected:** Returns to home page `/`
- [ ] Repeat on all dashboards: Demo Restaurant, Demo Hotel, Demo Taxi, Demo Admin, Account

### Swipe Right Gesture
- [ ] Navigate to **Demo Rider** dashboard
- [ ] **Swipe RIGHT** from left edge of screen (50px+ distance)
- [ ] **Expected:** Returns to home page `/`
- [ ] Ensure swipe is **quick** (< 500ms) and **minimal vertical movement**
- [ ] **Repeat on:** All dashboards, search page, verification page

**Improved Detection Parameters:**
- Minimum horizontal distance: 50px
- Maximum vertical variance: 50px
- Maximum swipe time: 500ms
- Uses `clientX`/`clientY` (not `screenX`/`screenY`)

---

## 📍 LOCATION VALIDATION

### Location Service
- [ ] Service file exists: `src/services/locationValidationService.ts`
- [ ] Contains functions:
  - [ ] `validateLocationForRoute()` - Checks 5km radius
  - [ ] `validateRestaurantLocation()` - Checks 2km radius
  - [ ] `calculateDistance()` - Haversine formula
  - [ ] `getUserLocation()` - Capacitor Geolocation API
- [ ] Station coordinates defined for: Lusaka, Livingstone, Ndola, Kitwe, Chipata, Mongu, Kasama, Solwezi

### Testing (When Integrated)
- [ ] Allow location permission when prompted
- [ ] User within 5km of from-location can book
- [ ] User outside 5km gets validation error
- [ ] Message shows distance to nearest station
- [ ] Works in demo mode

---

## 🎯 BUTTON NAVIGATION

### Main Buttons
- [ ] **"Order Now"** on hero → Navigates to `/dashboard`
- [ ] **"For Restaurants"** on hero → Navigates to `/restaurant`
- [ ] **"Popular Routes"** cards → Prefill search + navigate

### Navbar (Persistent)
- [ ] **Account** → `/account`
- [ ] **Dashboard** → `/dashboard`
- [ ] **Service Providers** → `/restaurant` (or `/rider`/`/taxi`/`/hotel`)
- [ ] **Riders** → `/rider`
- [ ] **Sign Out** → Clears auth, returns to home

### Mobile Menu
- [ ] Hamburg menu opens/closes
- [ ] Menu items navigation work
- [ ] Menu closes after selection

---

## 👤 VERIFICATION SYSTEM

### Access Point
- [ ] Route `/verification` accessible
- [ ] `ServiceProviderVerification` component loads
- [ ] Select role: Driver, Restaurant, Hotel, Taxi Driver

### For drivers/service providers:
- [ ] Form appears with required fields
- [ ] Submit button works
- [ ] Success message or error handling

---

## 🚀 DEMO MODE

### Demo Data
- [ ] Demo Rider accessible with demo credentials
- [ ] Demo Restaurant accessible
- [ ] Demo Hotel accessible
- [ ] Demo Taxi accessible
- [ ] Demo Admin accessible

### Demo Dashboard Features
- [ ] Stats display (earnings, trips, etc.)
- [ ] Back button/swipe works in demo mode
- [ ] Can switch between demo roles
- [ ] Logout returns to home page

---

## 🔧 BUILD & DEPLOYMENT

### Current Build Status
- **Status:** ✅ BUILD SUCCESSFUL in 11s
- **APK Size:** 5.06 MB
- **Location:** `android/app/build/outputs/apk/debug/app-debug.apk`
- **Timestamp:** 2026-02-24 15:58

### Installation
```bash
adb uninstall com.busnstay.app
adb install c:\Users\zwexm\LPSN\busnstay-journey-map-main\android\app\build\outputs\apk\debug\app-debug.apk
```

---

## 📋 PENDING FEATURES (To Implement Next)

- [ ] Location validation enforcement in journey search
- [ ] Restaurant filtering (approved only)
- [ ] Dynamic pricing (K20 base + distance fee)
- [ ] Google Maps integration
- [ ] Payment system (banks/mobile money)
- [ ] Hotel room images and availability
- [ ] Taxi driver location selection (Uber-style)
- [ ] Restaurant dashboard order receipt
- [ ] Station registration and order flow

---

## 🐛 DEBUG INFO

**Swipe Detection Logs:**
- Open Chrome DevTools → Console
- Perform swipe gesture
- Should see: `Swipe detected: deltaX=XX, deltaY=XX, time=XXms`

**Console Commands:**
```javascript
// Check if Capacitor is loaded
window.capacitorPlugins?.App

// Check touch event listener setup
// (View via DevTools Event Listener Breakpoints)
```

---

## ✅ TEST SIGN-OFF

- [ ] All back navigation works
- [ ] All button navigation works
- [ ] Swipe detection responsive
- [ ] No console errors
- [ ] App doesn't crash on navigation
- [ ] Demo mode fully functional

**Tester Name:** ________________  
**Date Tested:** ________________  
**Issues Found:** (List any issues below)

