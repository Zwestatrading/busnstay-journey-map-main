# ============================================================================
# REBUILD_APK_WITH_LOGO.ps1
# ============================================================================
# Rebuilds APK with the Logo.png integrated as app icon
# ============================================================================

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Rebuilding APK with BusNStay Logo Icon                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\Users\zwexm\LPSN\busnstay-journey-map-main"
Set-Location $projectPath

Write-Host "Step 1: Rebuild web app..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Web app built successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Sync Capacitor..." -ForegroundColor Yellow
npx cap sync android
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Capacitor sync failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Capacitor synced" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Build APK with logo icon..." -ForegroundColor Yellow
Set-Location "$projectPath\android"
$env:JAVA_HOME = "C:\Users\zwexm\.jdk\jdk-17.0.16"
.\gradlew clean assembleDebug
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ APK build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ APK built successfully" -ForegroundColor Green
Write-Host ""

$apkPath = "$projectPath\android\app\build\outputs\apk\debug\app-debug.apk"
if (Test-Path $apkPath) {
    $size = [math]::Round((Get-Item $apkPath).Length / 1024 / 1024, 2)
    Write-Host "✓ APK ready for installation!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Location: $apkPath" -ForegroundColor Cyan
    Write-Host "Size: $size MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To install on device:" -ForegroundColor Yellow
    Write-Host "  adb install -r $apkPath" -ForegroundColor Green
} else {
    Write-Host "✗ APK file not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✓ Rebuild complete!" -ForegroundColor Green
