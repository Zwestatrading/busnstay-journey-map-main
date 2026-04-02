# BusNStay Flutter App - Complete Implementation Guide

## Project Setup

### 1. Flutter Project Structure

```
busnstay_flutter/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── config/
│   │   ├── app_config.dart                # Configuration
│   │   ├── theme.dart                     # Material theme matching Tailwind
│   │   └── constants.dart                 # App constants
│   ├── models/
│   │   ├── user.dart
│   │   ├── journey.dart
│   │   ├── bus.dart
│   │   ├── restaurant.dart
│   │   ├── hotel.dart
│   │   └── auth.dart
│   ├── services/
│   │   ├── auth_service.dart              # Supabase auth
│   │   ├── user_service.dart              # User management
│   │   ├── journey_service.dart           # Bus journeys
│   │   ├── restaurant_service.dart        # Restaurant management
│   │   ├── hotel_service.dart             # Hotel management
│   │   ├── payment_service.dart           # Flutterwave integration
│   │   ├── location_service.dart          # GPS & location
│   │   ├── notification_service.dart      # Push notifications
│   │   └── analytics_service.dart         # Analytics
│   ├── providers/                         # State management (Riverpod)
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── journey_provider.dart
│   │   ├── restaurant_provider.dart
│   │   ├── hotel_provider.dart
│   │   └── payment_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── verify_email_screen.dart
│   │   │   ├── passenger_register_screen.dart
│   │   │   ├── operator_register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart           # Main dashboard
│   │   │   ├── journey_search_screen.dart # Search journeys
│   │   │   ├── journey_detail_screen.dart # Journey details
│   │   │   └── seat_selection_screen.dart # Seat booking
│   │   ├── restaurant/
│   │   │   ├── restaurant_list_screen.dart
│   │   │   ├── restaurant_detail_screen.dart
│   │   │   ├── menu_screen.dart
│   │   │   ├── cart_screen.dart
│   │   │   └── checkout_screen.dart
│   │   ├── hotel/
│   │   │   ├── hotel_list_screen.dart
│   │   │   ├── hotel_detail_screen.dart
│   │   │   ├── room_selection_screen.dart
│   │   │   ├── room_booking_screen.dart
│   │   │   └── checkout_screen.dart
│   │   ├── delivery/
│   │   │   ├── delivery_tracking_screen.dart
│   │   │   ├── delivery_list_screen.dart
│   │   │   └── delivery_map_screen.dart
│   │   ├── account/
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   ├── payment_methods_screen.dart
│   │   │   ├── saved_addresses_screen.dart
│   │   │   ├── order_history_screen.dart
│   │   │   └── loyalty_screen.dart
│   │   ├── admin/
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── user_management_screen.dart
│   │   │   ├── analytics_screen.dart
│   │   │   └── dispute_management_screen.dart
│   │   └── splash_screen.dart
│   ├── widgets/
│   │   ├── custom_app_bar.dart
│   │   ├── custom_bottom_nav.dart
│   │   ├── journey_card.dart
│   │   ├── bus_seat_selector.dart
│   │   ├── restaurant_card.dart
│   │   ├── hotel_card.dart
│   │   ├── room_card.dart
│   │   ├── loyalty_badge.dart
│   │   ├── payment_method_selector.dart
│   │   ├── loading_shimmer.dart
│   │   ├── error_widget.dart
│   │   ├── date_time_picker.dart
│   │   ├── location_input.dart
│   │   ├── rating_widget.dart
│   │   └── custom_button.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── extensions.dart
│   │   ├── permissions_handler.dart
│   │   └── logger.dart
│   └── l10n/                              # Localization
│       ├── app_en.arb
│       └── app_sw.arb
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## pubspec.yaml

```yaml
name: busnstay_flutter
description: "BusNStay - African Transportation & Delivery Platform"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  riverpod_generator: ^2.3.0

  # HTTP & API
  dio: ^5.3.0
  http: ^1.1.0

  # Supabase
  supabase_flutter: ^1.10.0
  supabase: ^1.10.0

  # UI & Design
  flutter_screenutil: ^5.9.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flip_card: ^0.7.0
  intl: ^0.19.0

  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.0

  # Payment Gateway
  flutterwave_standard: ^1.0.0
  provider: ^6.0.0

  # Firebase & Notifications
  firebase_core: ^2.24.0
  firebase_messaging: ^14.6.0
  firebase_analytics: ^10.7.0

  # Storage & Persistence
  shared_preferences: ^2.2.0
  get_storage: ^2.1.0
  hive: ^2.2.0
  hive_flutter: ^1.1.0

  # Image & Photo
  image_picker: ^1.0.0
  image_cropper: ^5.0.0
  photo_manager: ^2.7.0

  # Date & Time
  table_calendar: ^3.0.0
  datetime_picker_formfield_new: ^2.2.0

  # Video & Media
  video_player: ^2.8.0
  file_picker: ^6.0.0

  # Local Notifications
  flutter_local_notifications: ^16.2.0

  # Utilities
  uuid: ^4.0.0
  get: ^4.6.0
  connectivity_plus: ^5.0.0
  device_info_plus: ^9.1.0
  package_info_plus: ^5.0.0
  url_launcher: ^6.2.0
  share_plus: ^7.1.0
  qr_flutter: ^4.1.0

  # Dio logging
  dio_smart_retry: ^5.0.0
  pretty_logger: ^1.0.0

  # Bottom sheet
  bottom_sheet: ^4.0.0
  persistent_bottom_sheet: ^4.0.0

  # PDF
  pdf: ^3.10.0
  printing: ^5.11.0

  # Animations
  lottie: ^2.6.0
  flutter_animate: ^4.2.0

  # Device info
  android_id: ^0.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0

  # Testing
  mockito: ^5.4.0
  freezed: ^2.4.0

flutter_gen:
  output: lib/gen
  line_length: 80

flutter_intl:
  enabled: true
  default_locale: en
  locales:
    - en
    - sw
```

---

## Configuration Files

### lib/config/theme.dart

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusNStayTheme {
  // Primary Colors (Matching Tailwind config)
  static const Color primary = Color(0xFF3B82F6);        // Blue
  static const Color primaryForeground = Color(0xFFFFFFFF);
  
  static const Color secondary = Color(0xFFF59E0B);      // Amber
  static const Color secondaryForeground = Color(0xFFFFFFFF);
  
  static const Color accent = Color(0xFF10B981);         // Green
  static const Color accentForeground = Color(0xFFFFFFFF);
  
  static const Color destructive = Color(0xFFEF4444);    // Red
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  
  static const Color warning = Color(0xFFFCA5A5);        // Light Red
  static const Color warningForeground = Color(0xFF7F1D1D);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1F2937);
  static const Color foreground = Color(0xFF111827);
  
  // Neutral Colors
  static const Color muted = Color(0xFFF3F4F6);
  static const Color mutedDark = Color(0xFF374151);
  static const Color mutedForeground = Color(0xFF6B7280);
  
  // Journey Status Colors (Custom)
  static const Color journeyCompleted = Color(0xFF10B981);
  static const Color journeyActive = Color(0xFF3B82F6);
  static const Color journeyUpcoming = Color(0xFFFCA5A5);

  // Service Colors
  static const Color serviceRestaurant = Color(0xFFDC2626);
  static const Color serviceHotel = Color(0xFF9333EA);
  static const Color serviceRider = Color(0xFF06B6D4);
  static const Color serviceTaxi = Color(0xFFEAB308);

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        error: destructive,
        surface: background,
        onPrimary: primaryForeground,
        onSecondary: secondaryForeground,
        onError: destructiveForeground,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spacegrotesk(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          color: mutedForeground,
          fontSize: 14,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      cardTheme: CardTheme(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.spacegrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displayMedium: GoogleFonts.spacegrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        headlineLarge: GoogleFonts.spacegrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        headlineMedium: GoogleFonts.spacegrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: foreground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: foreground,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedForeground,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        error: destructive,
        surface: backgroundDark,
      ),

      // Similar configuration for dark theme...
    );
  }
}
```

### lib/config/constants.dart

```dart
class AppConstants {
  // API Configuration
  static const String supabaseUrl = 'https://ksepddxhvfkjfvnaervh.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_I97gCQ3PcClNtAvJ6SYdiQ_WBaYLm6O';
  
  // Flutterwave Configuration
  static const String flutterwavePublicKey = 'd7f4d56f-451d-4765-9df5-29be37a11782';
  static const String flutterwaveEnvironment = 'staging';
  
  // OSRM Configuration
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
  
  // App Configuration
  static const String appName = 'BusNStay';
  static const String appVersion = '1.0.0';
  static const String currency = 'ZMW';
  static const String defaultLanguage = 'en';
  
  // Platform Fee
  static const double platformFeePercentage = 0.10; // 10%
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Location
  static const double defaultZoom = 12.0;
  static const double searchRadiusKm = 50.0;
  
  // Loyalty Tiers
  static const Map<String, int> loyaltyThresholds = {
    'bronze': 0,
    'silver': 1000,
    'gold': 5000,
    'platinum': 10000,
  };
}
```

---

## Key Implementation Files

### lib/services/auth_service.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required bool termsAccepted,
  }) async {
    try {
      // 1. Create auth user
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) throw Exception('User creation failed');

      // 2. Create user profile
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'username': email.split('@')[0],
        'full_name': fullName,
        'phone_number': phoneNumber,
        'terms_accepted': termsAccepted,
      });

      // 3. Assign passenger role
      await _supabase.from('user_roles').insert({
        'user_id': userId,
        'role': 'passenger',
        'is_active': true,
      });

      // 4. Create passenger profile
      await _supabase.from('passenger_profiles').insert({
        'user_id': userId,
      });

      return {'success': true, 'userId': userId};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Login failed');

      // Fetch user profile
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      // Fetch user roles
      final roles = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Store session
      await _prefs.setString('auth_token', response.session?.accessToken ?? '');
      await _prefs.setString('userId', user.id);

      return {
        'success': true,
        'user': userData,
        'roles': roles,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Logout user
  Future<void> logout() async {
    await _supabase.auth.signOut();
    await _prefs.remove('auth_token');
    await _prefs.remove('userId');
  }

  // Get current user
  User? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return User(
      id: user.id,
      email: user.email ?? '',
      fullName: '',
      phoneNumber: '',
      createdAt: user.createdAt,
    );
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
}
```

### lib/providers/auth_provider.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

final loginProvider = FutureProvider.family<Map<String, dynamic>, ({String email, String password})>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.login(
    email: params.email,
    password: params.password,
  );
});

final registerProvider = FutureProvider.family<Map<String, dynamic>, ({
  String email,
  String password,
  String fullName,
  String phoneNumber,
  bool termsAccepted,
})>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.register(
    email: params.email,
    password: params.password,
    fullName: params.fullName,
    phoneNumber: params.phoneNumber,
    termsAccepted: params.termsAccepted,
  );
});
```

---

## Main App Entry Point

### lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return const BusNStayApp();
        },
      ),
    ),
  );
}

class BusNStayApp extends ConsumerWidget {
  const BusNStayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: BusNStayTheme.getLightTheme(),
      darkTheme: BusNStayTheme.getDarkTheme(),
      themeMode: ThemeMode.system,
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (error, stack) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: $error')),
            ),
          );
        },
        data: (auth) {
          return auth.session == null ? const LoginScreen() : const HomeScreen();
        },
      ),
    );
  }
}
```

---

## Screens Implementation

### lib/screens/auth/login_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(
      loginProvider((
        email: _emailController.text,
        password: _passwordController.text,
      )).future,
    );

    if (result['success'] == false) {
      setState(() {
        _errorMessage = result['error'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),
              
              // Logo
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: BusNStayTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Text(
                    'BusNStay',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),

              SizedBox(height: 40.h),

              // Title
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              Text(
                'Sign in to your account',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: BusNStayTheme.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: BusNStayTheme.destructive),
                  ),
                ),

              SizedBox(height: 16.h),

              // Email field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 16.h),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),

              SizedBox(height: 24.h),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign In'),
              ),

              SizedBox(height: 16.h),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### lib/screens/home/home_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/theme.dart';
import '../../widgets/custom_bottom_nav.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusNStay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick access cards
            Text(
              'Services',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16.h),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              children: [
                _ServiceCard(
                  icon: Icons.directions_bus,
                  title: 'Journeys',
                  color: BusNStayTheme.serviceRider,
                  onTap: () {},
                ),
                _ServiceCard(
                  icon: Icons.restaurant,
                  title: 'Restaurants',
                  color: BusNStayTheme.serviceRestaurant,
                  onTap: () {},
                ),
                _ServiceCard(
                  icon: Icons.hotel,
                  title: 'Hotels',
                  color: BusNStayTheme.serviceHotel,
                  onTap: () {},
                ),
                _ServiceCard(
                  icon: Icons.local_shipping,
                  title: 'Delivery',
                  color: BusNStayTheme.serviceTaxi,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.sp, color: color),
            SizedBox(height: 8.h),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Models

### lib/models/user.dart

```dart
class User {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? profileImageUrl;
  final String accountStatus;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.profileImageUrl,
    this.accountStatus = 'active',
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.twoFactorEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      accountStatus: json['account_status'] as String? ?? 'active',
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'account_status': accountStatus,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'two_factor_enabled': twoFactorEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

---

## Deployment Checklist

- [ ] Create new Flutter project: `flutter create busnstay_flutter`
- [ ] Copy all files from this guide
- [ ] Update `pubspec.yaml` with all dependencies
- [ ] Run `flutter pub get`
- [ ] Update Supabase configuration in `constants.dart`
- [ ] Update Flutterwave keys
- [ ] Generate Firebase options: `flutterfire configure`
- [ ] Test on Android emulator: `flutter run`
- [ ] Build release APK: `flutter build apk --release`
- [ ] Build iOS app: `flutter build ios`
- [ ] Deploy to Google Play Store
- [ ] Deploy to Apple App Store

---

## Optional: Web Version

Flutter Web allows you to deploy this as a web app too:

```bash
# Build web version
flutter build web

# Deploy to Firebase Hosting
firebase deploy

# Or deploy to Vercel
vercel deploy dist/web
```

This approach gives you:
✅ Single codebase for Android, iOS, Web
✅ All existing integrations (Supabase, Flutterwave, OSRM)
✅ Consistent styling and branding
✅ Multi-user management with role-based access
✅ Progressive deployment across platforms
