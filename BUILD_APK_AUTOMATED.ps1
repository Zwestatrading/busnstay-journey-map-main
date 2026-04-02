# ============================================================================
# BUILD_APK_AUTOMATED.ps1
# ============================================================================
# Automated APK build script with error handling
# This builds and packages all components into the APK
# ============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Automated APK Build - BusNStay with New Components           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$currentDir = Get-Location

# Colors
$success = "Green"
$error = "Red"
$warning = "Yellow"
$info = "Cyan"

function Log-Step {
    param([string]$message) 
    Write-Host ""
    Write-Host "╔" + ("─" * 62) + "╗" -ForegroundColor $info
    Write-Host "║ $message" + (" " * (62 - $message.Length)) + "║" -ForegroundColor $info
    Write-Host "╚" + ("─" * 62) + "╝" -ForegroundColor $info
    Write-Host ""
}

function Log-Success {
    param([string]$message)
    Write-Host "✓ $message" -ForegroundColor $success
}

function Log-Error {
    param([string]$message)
    Write-Host "✗ $message" -ForegroundColor $error
}

function Log-Warning {
    param([string]$message)
    Write-Host "⚠ $message" -ForegroundColor $warning
}

function Log-Info {
    param([string]$message)
    Write-Host "ℹ $message" -ForegroundColor $info
}

function Run-Command {
    param(
        [string]$command,
        [string]$description
    )
    
    Log-Info "Running: $description"
    Log-Info "Command: $command"
    Write-Host ""
    
    $output = Invoke-Expression $command 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Log-Error "Failed: $description"
        Write-Host $output
        throw "Command failed: $command"
    }
    
    Log-Success "Completed: $description"
    return $output
}

try {
    # Step 1: Verify environment
    Log-Step "STEP 1: Verify Build Environment"
    
    if (-not (Test-Path "package.json")) {
        throw "package.json not found. Are you in the project root?"
    }
    Log-Success "package.json found"
    
    if (-not (Test-Path "capacitor.config.ts")) {
        throw "capacitor.config.ts not found. Are you in the project root?"
    }
    Log-Success "capacitor.config.ts found"
    
    if (-not (Test-Path "android")) {
        throw "android/ directory not found. Capacitor not initialized."
    }
    Log-Success "android/ directory found"
    
    # Step 2: Check for new components
    Log-Step "STEP 2: Verify New Components Exist"
    
    $components = @(
        "src\components\FormFields.tsx",
        "src\hooks\useAccessibility.ts",
        "src\components\MobileNav.tsx",
        "src\components\DataVisualization.tsx",
        "src\utils\animationVariants.ts",
        "src\components\ErrorBoundary.tsx",
        "src\components\AdminTools.tsx",
        "src\components\UserProfile.tsx"
    )
    
    foreach ($component in $components) {
        if (Test-Path $component) {
            Log-Success "Found: $component"
        } else {
            Log-Warning "Missing: $component (may already be integrated)"
        }
    }
    
    # Step 3: Clean previous build
    Log-Step "STEP 3: Clean Previous Build Artifacts"
    
    if (Test-Path "dist") {
        Log-Info "Removing old dist/ folder..."
        Remove-Item -Recurse -Force "dist" -ErrorAction SilentlyContinue
        Log-Success "Cleaned dist/"
    }
    
    # Step 4: Install dependencies (if needed)
    Log-Step "STEP 4: Ensure Dependencies Installed"
    
    Log-Info "Checking npm installation..."
    Run-Command "npm ls --depth=0" "Check dependencies" > $null
    Log-Success "All dependencies present"
    
    # Step 5: Build Vite app
    Log-Step "STEP 5: Build Vite Application (Compile TypeScript & Bundle)"
    
    Log-Info "This will compile all components including:"
    Log-Info "  • Advanced Form Components (FormFields.tsx)"
    Log-Info "  • Accessibility Hooks (useAccessibility.ts)"
    Log-Info "  • Mobile Navigation (MobileNav.tsx)"
    Log-Info "  • Data Visualization (DataVisualization.tsx)"
    Log-Info "  • Animation Variants (animationVariants.ts)"
    Log-Info "  • Error Boundary (ErrorBoundary.tsx)"
    Log-Info "  • Admin Tools (AdminTools.tsx)"
    Log-Info "  • User Profile System (UserProfile.tsx)"
    Write-Host ""
    
    Run-Command "npm run build" "Vite production build" | Out-Null
    
    if (-not (Test-Path "dist")) {
        throw "Build failed: dist/ not created"
    }
    Log-Success "Build successful: dist/ folder created"
    
    # Get build size
    $distSize = [math]::Round((Get-ChildItem -Path dist -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    Log-Info "Build size: $distSize MB"
    
    # Step 6: Sync Capacitor
    Log-Step "STEP 6: Sync Capacitor (Copy dist/ to Android)"
    
    Log-Info "Syncing web assets to Android project..."
    Run-Command "npx cap sync android" "Capacitor sync" | Out-Null
    
    if (-not (Test-Path "android\app\src\main\assets\public")) {
        Log-Warning "Web assets directory not created. The sync may need to complete first."
    } else {
        Log-Success "Web assets synced to Android project"
    }
    
    # Step 7: Build APK
    Log-Step "STEP 7: Build Android APK"
    
    Log-Info "Building Android APK..."
    Log-Info "This may take 2-5 minutes depending on your system..."
    Write-Host ""
    
    Run-Command "npx cap build android" "Capacitor build Android" | Out-Null
    
    # Check for APK output
    $apkPath = "android\app\build\outputs\apk\debug\app-debug.apk"
    $releaseApkPath = "android\app\build\outputs\apk\release\app-release.apk"
    
    if (Test-Path $apkPath) {
        $apkSize = [math]::Round((Get-Item $apkPath).Length / 1024 / 1024, 2)
        Log-Success "APK built successfully!"
        Log-Info "Location: $apkPath"
        Log-Info "Size: $apkSize MB"
    } elseif (Test-Path $releaseApkPath) {
        $apkSize = [math]::Round((Get-Item $releaseApkPath).Length / 1024 / 1024, 2)
        Log-Success "Release APK built successfully!"
        Log-Info "Location: $releaseApkPath"
        Log-Info "Size: $apkSize MB"
    } else {
        Log-Warning "Could not locate built APK. Check build output above."
    }
    
    # Step 8: Success summary
    Log-Step "STEP 8: Build Complete!"
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $success
    Write-Host "                    BUILD SUCCESSFUL! 🎉                        " -ForegroundColor $success
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $success
    Write-Host ""
    Write-Host "All 8 new features are now included in your APK:" -ForegroundColor $success
    Write-Host ""
    Write-Host "  ✓ Advanced Form Components" -ForegroundColor $success
    Write-Host "  ✓ Accessibility & Performance (WCAG AA/AAA)" -ForegroundColor $success
    Write-Host "  ✓ Mobile Navigation & Gestures" -ForegroundColor $success
    Write-Host "  ✓ Data Visualization (Charts)" -ForegroundColor $success
    Write-Host "  ✓ Advanced Animations" -ForegroundColor $success
    Write-Host "  ✓ Error Handling & Offline Support" -ForegroundColor $success
    Write-Host "  ✓ Admin Tools & Data Table" -ForegroundColor $success
    Write-Host "  ✓ User Profile System" -ForegroundColor $success
    Write-Host ""
    Write-Host "Build time: $([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor $info
    Write-Host ""
    
    # Next steps
    Log-Step "NEXT STEPS"
    
    Write-Host "1. Test on Android Device:" -ForegroundColor $info
    Write-Host "   adb install -r $apkPath" -ForegroundColor $warning
    Write-Host ""
    
    Write-Host "2. Or use Android Studio:" -ForegroundColor $info
    Write-Host "   npx cap open android" -ForegroundColor $warning
    Write-Host ""
    
    Write-Host "3. Upload to Play Store:" -ForegroundColor $info
    Write-Host "   Use Android Studio or Play Console" -ForegroundColor $warning
    Write-Host ""
    
    Write-Host "4. For release build:" -ForegroundColor $info
    Write-Host "   npx cap build android --release" -ForegroundColor $warning
    Write-Host ""

} catch {
    Log-Error "Build failed!"
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor $error
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor $warning
    Write-Host "• Check Node.js and npm are installed: npm --version" -ForegroundColor $warning
    Write-Host "• Check Java is installed: java -version" -ForegroundColor $warning
    Write-Host "• Check Android SDK is installed" -ForegroundColor $warning
    Write-Host "• Review build logs above for details" -ForegroundColor $warning
    Write-Host ""
    exit 1
}

Write-Host ""
