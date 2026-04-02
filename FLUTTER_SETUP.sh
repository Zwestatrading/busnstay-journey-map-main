#!/bin/bash

# BusNStay Flutter App - Automated Setup Script
# This script creates a new Flutter project with all necessary files

set -e

PROJECT_NAME="busnstay_flutter"
PACKAGE_NAME="com.busnstay.app"

echo "🚀 Creating BusNStay Flutter App..."

# Create Flutter project
flutter create --org com.busnstay --project-name busnstay_flutter $PROJECT_NAME
cd $PROJECT_NAME

echo "📦 Installing dependencies..."

# Update pubspec.yaml
cat > pubspec.yaml << 'EOF'
name: busnstay_flutter
description: "BusNStay - African Transportation & Delivery Platform"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  cupertino_icons: ^1.0.2
  
  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  
  # HTTP & API
  dio: ^5.3.0
  
  # Supabase
  supabase_flutter: ^1.10.0
  supabase: ^1.10.0
  
  # UI & Design
  flutter_screenutil: ^5.9.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  
  # Payment Gateway
  flutterwave_standard: ^1.0.0
  
  # Storage & Persistence
  shared_preferences: ^2.2.0
  
  # Notifications
  firebase_core: ^2.24.0
  firebase_messaging: ^14.6.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.0.0
  get: ^4.6.0
  connectivity_plus: ^5.0.0
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
    - family: SpaceGrotesk
      fonts:
        - asset: assets/fonts/SpaceGrotesk-Regular.ttf
        - asset: assets/fonts/SpaceGrotesk-Bold.ttf
          weight: 700
EOF

# Create directory structure
mkdir -p lib/{config,models,services,providers,screens/{auth,home,restaurant,hotel,delivery,account,admin},widgets,utils,l10n}
mkdir -p assets/{images,icons,animations,fonts}
mkdir -p test

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. flutter pub get"
echo "3. Update lib/config/constants.dart with your API keys"
echo "4. Run: flutter run"
echo ""
echo "To create release APK:"
echo "flutter build apk --release"
EOF
