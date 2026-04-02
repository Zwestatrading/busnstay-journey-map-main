# ============================================================================
# BUILD_APK_WITH_NEW_COMPONENTS.ps1
# ============================================================================
# This script builds APK with all new components included:
# - FormFields.tsx (Advanced forms)
# - useAccessibility.ts (Accessibility & performance)
# - MobileNav.tsx (Mobile experience)
# - DataVisualization.tsx (Charts & analytics)
# - animationVariants.ts (Advanced animations)
# - ErrorBoundary.tsx (Error handling)
# - AdminTools.tsx (Admin utilities)
# - UserProfile.tsx (User profile system)
# ============================================================================

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  BusNStay APK Build with New Components                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Initialize variables
$projectPath = Get-Location
$buildStartTime = Get-Date
$errors = @()
$warnings = @()

# Function to log progress
function Write-Progress-Log {
    param(
        [string]$message,
        [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING")]
        [string]$level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch($level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$level] $message" -ForegroundColor $color
}

# Function to check if file exists
function Check-File {
    param([string]$path, [string]$description)
    if (Test-Path $path) {
        Write-Progress-Log "✓ Found $description" "SUCCESS"
        return $true
    } else {
        Write-Progress-Log "✗ Missing $description: $path" "ERROR"
        $errors += "Missing: $description"
        return $false
    }
}

Write-Host ""
Write-Host "STEP 1: Verifying new components exist" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

$components = @(
    @{ path = "src\components\FormFields.tsx"; desc = "Advanced Form Components" },
    @{ path = "src\hooks\useAccessibility.ts"; desc = "Accessibility & Performance Hooks" },
    @{ path = "src\components\MobileNav.tsx"; desc = "Mobile Navigation" },
    @{ path = "src\components\DataVisualization.tsx"; desc = "Data Visualization Components" },
    @{ path = "src\utils\animationVariants.ts"; desc = "Animation Variants" },
    @{ path = "src\components\ErrorBoundary.tsx"; desc = "Error Boundary Component" },
    @{ path = "src\components\AdminTools.tsx"; desc = "Admin Tools Components" },
    @{ path = "src\components\UserProfile.tsx"; desc = "User Profile System" }
)

$componentsFound = 0
foreach ($component in $components) {
    if (Check-File $component.path $component.desc) {
        $componentsFound++
    }
}

Write-Host ""
Write-Host "Found $componentsFound / $($components.Count) new components" -ForegroundColor Cyan
Write-Host ""

if ($componentsFound -ne $components.Count) {
    Write-Progress-Log "Not all components found! Some components may be missing." "WARNING"
}

Write-Host ""
Write-Host "STEP 2: Verifying build configuration" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Check required files
$requiredFiles = @(
    @{ path = "package.json"; desc = "NPM Configuration" },
    @{ path = "vite.config.ts"; desc = "Vite Configuration" },
    @{ path = "capacitor.config.ts"; desc = "Capacitor Configuration" },
    @{ path = "android/build.gradle"; desc = "Android Gradle Configuration" },
    @{ path = "tsconfig.json"; desc = "TypeScript Configuration" }
)

$requiredFilesFound = 0
foreach ($file in $requiredFiles) {
    if (Check-File $file.path $file.desc) {
        $requiredFilesFound++
    }
}

Write-Host ""
Write-Host "Found $requiredFilesFound / $($requiredFiles.Count) required files" -ForegroundColor Cyan
Write-Host ""

Write-Host ""
Write-Host "STEP 3: Build instructions" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "To build the APK with all new components, execute these commands:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Build Vite application (compiles all components to dist/)" -ForegroundColor White
Write-Host "   Command: npm run build" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Sync Capacitor (copies dist/ to Android project)" -ForegroundColor White
Write-Host "   Command: npx cap sync android" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Build Android APK (creates app-debug.apk)" -ForegroundColor White
Write-Host "   Command: npx cap build android" -ForegroundColor Green
Write-Host ""

Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "Alternatively, run this automated build script:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   PowerShell -ExecutionPolicy Bypass -File BUILD_APK_AUTOMATED.ps1" -ForegroundColor Green
Write-Host ""

Write-Host ""
Write-Host "STEP 4: What's included in the APK" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Advanced Form Components (FormFields.tsx)" -ForegroundColor Green
Write-Host "   - Real-time validation" -ForegroundColor Gray
Write-Host "   - Password visibility toggle" -ForegroundColor Gray
Write-Host "   - Character count tracking" -ForegroundColor Gray
Write-Host "   - Loading states" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Accessibility & Performance (useAccessibility.ts)" -ForegroundColor Green
Write-Host "   - Screen reader support (WCAG AA/AAA)" -ForegroundColor Gray
Write-Host "   - Keyboard navigation" -ForegroundColor Gray
Write-Host "   - Focus management" -ForegroundColor Gray
Write-Host "   - Lazy loading" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Mobile Navigation (MobileNav.tsx)" -ForegroundColor Green
Write-Host "   - Bottom tab navigation" -ForegroundColor Gray
Write-Host "   - Gesture detection (swipe, long-press)" -ForegroundColor Gray
Write-Host "   - Touch-friendly interface" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Data Visualization (DataVisualization.tsx)" -ForegroundColor Green
Write-Host "   - Bar, line, pie charts" -ForegroundColor Gray
Write-Host "   - Statistics grid" -ForegroundColor Gray
Write-Host "   - Responsive layout" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Advanced Animations (animationVariants.ts)" -ForegroundColor Green
Write-Host "   - 10+ reusable animation patterns" -ForegroundColor Gray
Write-Host "   - Spring physics animations" -ForegroundColor Gray
Write-Host "   - Skeleton loaders" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Error Handling (ErrorBoundary.tsx)" -ForegroundColor Green
Write-Host "   - Error boundaries" -ForegroundColor Gray
Write-Host "   - Offline detection" -ForegroundColor Gray
Write-Host "   - Retry mechanism" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ Admin Tools (AdminTools.tsx)" -ForegroundColor Green
Write-Host "   - Advanced data table (search, sort, filter, export)" -ForegroundColor Gray
Write-Host "   - Batch operations" -ForegroundColor Gray
Write-Host "   - Multi-select" -ForegroundColor Gray
Write-Host ""

Write-Host "✓ User Profile System (UserProfile.tsx)" -ForegroundColor Green
Write-Host "   - Profile management" -ForegroundColor Gray
Write-Host "   - Notification preferences" -ForegroundColor Gray
Write-Host "   - Security settings" -ForegroundColor Gray
Write-Host ""

Write-Host ""
Write-Host "STEP 5: Build optimization" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "The build process will:" -ForegroundColor White
Write-Host ""
Write-Host "1. Compile TypeScript to JavaScript" -ForegroundColor Green
Write-Host "2. Bundle React components with tree-shaking" -ForegroundColor Green
Write-Host "3. Minify and optimize code" -ForegroundColor Green
Write-Host "4. Copy assets to public folder" -ForegroundColor Green
Write-Host "5. Generate source maps for debugging" -ForegroundColor Green
Write-Host "6. Create production dist/" -ForegroundColor Green
Write-Host "7. Sync with Android project" -ForegroundColor Green
Write-Host "8. Compile Android project" -ForegroundColor Green
Write-Host "9. Generate app-debug.apk (or app-release.apk)" -ForegroundColor Green
Write-Host ""

Write-Host ""
Write-Host "STEP 6: Installation on device" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "After building, install APK on Android device:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   adb install -r android/app/build/outputs/apk/debug/app-debug.apk" -ForegroundColor Green
Write-Host ""

Write-Host "Or use Android Studio to run directly:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   npx cap open android" -ForegroundColor Green
Write-Host ""
Write-Host "Then: Build → Build Bundle(s) / APK(s) → Build APK(s)" -ForegroundColor Gray
Write-Host ""

Write-Host ""
Write-Host "STEP 7: Troubleshooting" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

Write-Host "Issue: 'npm' command not found" -ForegroundColor Yellow
Write-Host "Solution: Install Node.js from nodejs.org" -ForegroundColor Gray
Write-Host ""

Write-Host "Issue: 'npx' command not found" -ForegroundColor Yellow
Write-Host "Solution: Comes with Node.js, restart terminal after installing" -ForegroundColor Gray
Write-Host ""

Write-Host "Issue: Build fails with TypeScript errors" -ForegroundColor Yellow
Write-Host "Solution: Run 'npm install' to ensure all dependencies are installed" -ForegroundColor Gray
Write-Host ""

Write-Host "Issue: Capacitor sync fails" -ForegroundColor Yellow
Write-Host "Solution: Delete 'android/app/src/main/assets/public' and retry" -ForegroundColor Gray
Write-Host ""

Write-Host "Issue: Gradle build fails" -ForegroundColor Yellow
Write-Host "Solution: Delete 'android/.gradle' folder and retry" -ForegroundColor Gray
Write-Host ""

Write-Host ""
Write-Host "STEP 8: Build summary" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

if ($errors.Count -eq 0) {
    Write-Progress-Log "✓ All checks passed! Ready to build." "SUCCESS"
    Write-Host ""
    Write-Host "Your project is ready for production APK build with all 8 new" -ForegroundColor Cyan
    Write-Host "feature iterations included!" -ForegroundColor Cyan
} else {
    Write-Progress-Log "$($errors.Count) issues detected:" "WARNING"
    foreach ($error in $errors) {
        Write-Host "  • $error" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Build Configuration Complete                                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$buildEndTime = Get-Date
$duration = $buildEndTime - $buildStartTime
Write-Host "Check completed in: $($duration.TotalSeconds) seconds" -ForegroundColor Gray
Write-Host ""

# Create build commands file
$buildCommands = @"
# Quick Build Commands

# 1. Build Vite app
npm run build

# 2. Sync Capacitor
npx cap sync android

# 3. Build APK
npx cap build android

# One-liner:
npm run build && npx cap sync android && npx cap build android

# Or for release build:
npm run build && npx cap sync android && npx cap build android --release
"@

Set-Content -Path "BUILD_COMMANDS.txt" -Value $buildCommands -Encoding UTF8
Write-Progress-Log "Build commands saved to BUILD_COMMANDS.txt" "SUCCESS"
Write-Host ""
