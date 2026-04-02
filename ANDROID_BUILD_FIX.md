# Android APK Build Resolution Guide

## Issue: Java Version Compatibility Error

### Error Message
```
error: invalid source release: 21
Execution failed for task ':app:compileDebugJavaWithJavac'.
```

### Root Cause
The system has Java 21 installed as the primary JDK, but the Android Gradle build configuration is set to use Java 17.

### Quick Solutions

#### Option 1: Set JAVA_HOME Environment Variable (RECOMMENDED)

**For Windows PowerShell:**
```powershell
# Set to Java 17 explicitly
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.X"  # Replace X with your version

# Verify it worked
java -version

# Now rebuild
cd "c:\Users\zwexm\LPSN\busnstay-journey-map-main\android"
.\gradlew clean
.\gradlew assembleDebug
```

**For Command Prompt:**
```cmd
setx JAVA_HOME "C:\Program Files\Java\jdk-17.0.X"
```

#### Option 2: Update gradle.properties

Edit `android/gradle.properties`:
```properties
# Add or update these lines
org.gradle.java.home=C:\\Program Files\\Java\\jdk-17.0.X
org.gradle.jvmargs=-Xmx1024m
```

#### Option 3: Update Gradle JDK Settings

Edit `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
```

#### Option 4: Manual Gradle Build

```bash
cd "c:\Users\zwexm\LPSN\busnstay-journey-map-main\android"

# Use explicit Java 17 path
./gradlew assembleDebug -v -Dorg.gradle.java.home="C:\Program Files\Java\jdk-17.0.X"
```

---

## Installation of Java 17 (If Not Present)

### Option A: Using Installer
1. Download Java 17 LTS from https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html
2. Install to default location
3. Set JAVA_HOME environment variable

### Option B: Using Scoop (Windows)
```powershell
# Install scoop if not already installed
iwr -useb get.scoop.sh | iex

# Install Java 17
scoop install openjdk@17
```

### Option C: Using Chocolatey
```powershell
choco install openjdk17
```

---

## Verification Steps

### Check Current Java Version
```bash
java -version
javac -version
```

### Verify JAVA_HOME is Set
```powershell
# PowerShell
$env:JAVA_HOME

# Command Prompt
echo %JAVA_HOME%
```

### Verify Gradle Detects Java 17
```bash
cd "c:\Users\zwexm\LPSN\busnstay-journey-map-main\android"
.\gradlew --version
```

---

## Complete Build Process (After Resolution)

Once Java 17 is configured:

```bash
# Navigate to project
cd "c:\Users\zwexm\LPSN\busnstay-journey-map-main"

# Sync Capacitor (if needed)
npx cap sync android

# Clean previous build
cd android
.\gradlew clean

# Build APK
.\gradlew assembleDebug

# Verify APK created
# Output: android/app/build/outputs/apk/debug/app-debug.apk
```

## Alternative: Use Docker

If Java version conflicts persist, use Docker:

```bash
# Install Docker Desktop for Windows

# Run Gradle in Docker
docker run --rm -v "C:\Users\zwexm\LPSN\busnstay-journey-map-main\android:/workspace" -w "/workspace" gradle:8.5-jdk17 ./gradlew assembleDebug
```

---

## Installation on Android Device

Once APK is successfully built:

```bash
# Connect Android device via USB with USB debugging enabled

# Install APK
adb uninstall com.busnstay.app
adb install "c:\Users\zwexm\LPSN\busnstay-journey-map-main\android\app\build\outputs\apk\debug\app-debug.apk"

# Launch app
adb shell am start -n com.busnstay.app/com.getcapacitor.MainActivity

# View logs
adb logcat | grep BusNStay
```

---

## Troubleshooting

### Error: "JAVA_HOME is not set"
```bash
# Set it explicitly
set JAVA_HOME=C:\Program Files\Java\jdk-17.0.X
```

### Error: "java: command not found"
- Java is not installed
- JAVA_HOME is not set correctly
- Path doesn't include Java/bin

### Error: "Gradle build failed with unknown error"
```bash
# Run with full debug output
.\gradlew assembleDebug --stacktrace --debug
```

### Clean Rebuild If Still Issues
```bash
# Nuclear option - clean everything
cd android
.\gradlew clean
cd ..
rm -r android/app/build
rm -r .gradle
.\gradlew clean
.\gradlew assembleDebug
```

---

## Quick Reference Commands

```powershell
# List all Java versions installed
ls "C:\Program Files\Java\"

# Set Java 17 for current session only
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.11"

# Verify Gradle setup
cd "c:\Users\zwexm\LPSN\busnstay-journey-map-main\android"
.\gradlew help

# Force rebuild
.\gradlew assembleDebug --no-build-cache
```

---

## Support

If issues persist:
1. Check Java installation: `java -version` → Should show version 17.x.x
2. Check Gradle version: `.\gradlew --version` → Should show Gradle 8.5
3. Check JAVA_HOME: `echo %JAVA_HOME%` → Should point to Java 17 directory
4. Delete Gradle cache: `rm -r ~/.gradle`
5. Try with verbose output: `.\gradlew assembleDebug -v`

---

**Last Updated:** February 24, 2024
**Expected Build Time:** 3-5 minutes on first build, 1-2 minutes for incremental builds
