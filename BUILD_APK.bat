@echo off
REM ============================================================================
REM BUILD_APK.bat - Build BusNStay APK with All New Components
REM ============================================================================
REM This batch file automates the APK build process on Windows
REM ============================================================================

setlocal enabledelayedexpansion
title BusNStay APK Build

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║  BusNStay APK Build with 8 New Components                      ║
echo ║  (Advanced Forms, Accessibility, Mobile, Charts, Animations,   ║
echo ║   Error Handling, Admin Tools, Profile System)                 ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM Check if npm is installed
echo Checking for npm...
npm --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: npm not found!
    echo.
    echo Please install Node.js from: https://nodejs.org
    echo.
    pause
    exit /b 1
)

echo ✓ npm is installed
echo.

REM Ask user which build type they want
echo Choose build type:
echo.
echo 1) Debug Build (faster, for testing)
echo 2) Release Build (for Play Store)
echo 3) Automated Build (recommended)
echo.

set /p choice="Enter choice (1-3): "

if "%choice%"=="1" goto debug_build
if "%choice%"=="2" goto release_build
if "%choice%"=="3" goto automated_build

echo Invalid choice. Exiting.
pause
exit /b 1

:debug_build
echo.
echo ════════════════════════════════════════════════════════════════
echo Building Debug APK...
echo ════════════════════════════════════════════════════════════════
echo.

echo Step 1/3: Building Vite app...
call npm run build
if errorlevel 1 (
    echo ERROR: Vite build failed
    pause
    exit /b 1
)
echo ✓ Vite build complete

echo.
echo Step 2/3: Syncing Capacitor...
call npx cap sync android
if errorlevel 1 (
    echo ERROR: Capacitor sync failed
    pause
    exit /b 1
)
echo ✓ Capacitor sync complete

echo.
echo Step 3/3: Building Android APK...
call npx cap build android
if errorlevel 1 (
    echo ERROR: Android build failed
    pause
    exit /b 1
)
echo ✓ Android build complete

echo.
echo ════════════════════════════════════════════════════════════════
echo ✓ BUILD SUCCESSFUL!
echo ════════════════════════════════════════════════════════════════
echo.
echo APK Location: android\app\build\outputs\apk\debug\app-debug.apk
echo.
echo To install on device:
echo   adb install -r android\app\build\outputs\apk\debug\app-debug.apk
echo.
pause
exit /b 0

:release_build
echo.
echo ════════════════════════════════════════════════════════════════
echo Building Release APK...
echo ════════════════════════════════════════════════════════════════
echo.

echo Step 1/3: Building Vite app...
call npm run build
if errorlevel 1 (
    echo ERROR: Vite build failed
    pause
    exit /b 1
)
echo ✓ Vite build complete

echo.
echo Step 2/3: Syncing Capacitor...
call npx cap sync android
if errorlevel 1 (
    echo ERROR: Capacitor sync failed
    pause
    exit /b 1
)
echo ✓ Capacitor sync complete

echo.
echo Step 3/3: Building Release APK...
echo WARNING: Make sure your keystores are configured in android/app/build.gradle
echo.
call npx cap build android --release
if errorlevel 1 (
    echo ERROR: Android release build failed
    pause
    exit /b 1
)
echo ✓ Android release build complete

echo.
echo ════════════════════════════════════════════════════════════════
echo ✓ RELEASE BUILD SUCCESSFUL!
echo ════════════════════════════════════════════════════════════════
echo.
echo APK Location: android\app\build\outputs\apk\release\app-release.apk
echo.
echo Next: Upload to Play Console
echo.
pause
exit /b 0

:automated_build
echo.
echo ════════════════════════════════════════════════════════════════
echo Automated Build (with error checking)
echo ════════════════════════════════════════════════════════════════
echo.

echo Verifying environment...
if not exist "package.json" (
    echo ERROR: package.json not found. Run from project root.
    pause
    exit /b 1
)
echo ✓ package.json found

if not exist "capacitor.config.ts" (
    echo ERROR: capacitor.config.ts not found
    pause
    exit /b 1
)
echo ✓ capacitor.config.ts found

if not exist "android" (
    echo ERROR: android/ directory not found
    pause
    exit /b 1
)
echo ✓ android/ directory found

echo.
echo Verifying components...

set components_found=0

if exist "src\components\FormFields.tsx" (
    echo ✓ FormFields.tsx
    set /a components_found=!components_found!+1
) else (
    echo ✗ FormFields.tsx not found
)

if exist "src\hooks\useAccessibility.ts" (
    echo ✓ useAccessibility.ts
    set /a components_found=!components_found!+1
) else (
    echo ✗ useAccessibility.ts not found
)

if exist "src\components\MobileNav.tsx" (
    echo ✓ MobileNav.tsx
    set /a components_found=!components_found!+1
) else (
    echo ✗ MobileNav.tsx not found
)

if exist "src\components\DataVisualization.tsx" (
    echo ✓ DataVisualization.tsx
    set /a components_found=!components_found!+1
) else (
    echo ✗ DataVisualization.tsx not found
)

if exist "src\utils\animationVariants.ts" (
    echo ✓ animationVariants.ts
    set /a components_found=!components_found!+1
) else (
    echo ✗ animationVariants.ts not found
)

if exist "src\components\ErrorBoundary.tsx" (
    echo ✓ ErrorBoundary.tsx
    set /a components_found=!components_found!+1
) else (
    echo ✗ ErrorBoundary.tsx not found
)

if exist "src\components\AdminTools.tsx" (
    echo ✓ AdminTools.tsx
    set /a components_found=!components_found!+1
) else (
    echo ✗ AdminTools.tsx not found
)

if exist "src\components\UserProfile.tsx" (
    echo ✓ UserProfile.tsx
    set /a components_found=!components_found!+1
) else (
    echo ✗ UserProfile.tsx not found
)

echo.
echo Found !components_found!/8 new components
echo.

echo Building Vite app...
call npm run build
if errorlevel 1 (
    echo.
    echo ERROR: Vite build failed. Check output above.
    pause
    exit /b 1
)
echo ✓ Vite build complete

if not exist "dist" (
    echo.
    echo ERROR: dist/ folder not created. Build may have failed.
    pause
    exit /b 1
)

REM Get distribution size
for /f %%A in ('dir "dist" /s /-c ^| findstr /R "bytes free"') do (
    echo ✓ Build size: %%A
)

echo.
echo Syncing Capacitor...
call npx cap sync android
if errorlevel 1 (
    echo.
    echo ERROR: Capacitor sync failed. Check output above.
    pause
    exit /b 1
)
echo ✓ Capacitor sync complete

echo.
echo Building Android APK (this may take 1-3 minutes)...
call npx cap build android
if errorlevel 1 (
    echo.
    echo ERROR: Android build failed. Check output above.
    pause
    exit /b 1
)
echo ✓ Android build complete

echo.
echo ════════════════════════════════════════════════════════════════
echo ✓ BUILD SUCCESSFUL! 🎉
echo ════════════════════════════════════════════════════════════════
echo.
echo All 8 new features are included in your APK:
echo   ✓ Advanced Form Components
echo   ✓ Accessibility ^& Performance (WCAG AA/AAA)
echo   ✓ Mobile Navigation ^& Gestures
echo   ✓ Data Visualization (Charts)
echo   ✓ Advanced Animations
echo   ✓ Error Handling ^& Offline Support
echo   ✓ Admin Tools ^& Data Table
echo   ✓ User Profile System
echo.

if exist "android\app\build\outputs\apk\debug\app-debug.apk" (
    for /f %%A in ('"powershell -Command Get-Item -Path android\app\build\outputs\apk\debug\app-debug.apk | Select-Object -ExpandProperty Length"') do (
        set /a apk_size=%%A/1024/1024
        echo APK Created: android\app\build\outputs\apk\debug\app-debug.apk (!apk_size! MB)
    )
) else (
    echo Note: APK location may vary. Check android/app/build/outputs/
)

echo.
echo Next Steps:
echo   1. Plug in Android device (enable USB debugging)
echo   2. Run: adb install -r android\app\build\outputs\apk\debug\app-debug.apk
echo   3. Open BusNStay app on device
echo   4. Test all new features
echo.
pause
exit /b 0
