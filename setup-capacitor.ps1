# Capacitor Setup Script for Windows

# Change to project directory
cd c:\Users\zwexm\LPSN\busnstay-journey-map-main

Write-Host "=== Step 1: Install Capacitor Packages ===" -ForegroundColor Green
npm install @capacitor/core @capacitor/cli @capacitor/app @capacitor/geolocation --save-dev

Write-Host "=== Step 2: Add Android Platform ===" -ForegroundColor Green
npx cap add android

Write-Host "=== Step 3: Add iOS Platform ===" -ForegroundColor Green
npx cap add ios

Write-Host "=== Step 4: Build Web App ===" -ForegroundColor Green
npm run build

Write-Host "=== Step 5: Sync to Native ===" -ForegroundColor Green
npx cap sync

Write-Host "=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "  Android: npx cap build android"
Write-Host "  iOS: npx cap build ios"
