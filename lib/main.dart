import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'models/user_model.dart';
import 'models/wallet_model.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'services/order_management_service.dart';
import 'services/restaurant_notification_service.dart';
import 'services/town_order_management_service.dart';
import 'services/passenger_service.dart';
import 'services/restaurant_service.dart';
import 'services/bus_operator_service.dart';
import 'services/delivery_service.dart';
import 'services/hotel_service.dart';
import 'services/live_location_service.dart';
import 'services/menu_management_service.dart';
import 'widgets/payment_modal.dart';
import 'widgets/status_badge.dart';
import 'pages/forgot_password_page.dart';
import 'pages/passenger_experience_page.dart';
import 'pages/upgraded_bus_operator_dashboard.dart';
import 'pages/upgraded_delivery_agent_dashboard.dart';
import 'pages/upgraded_hotel_manager_dashboard.dart';
import 'pages/upgraded_restaurant_admin_dashboard.dart';

// ============ APP SERVICES SINGLETON ============
class AppServices {
  static late OrderManagementService orderService;
  static late RestaurantNotificationService notificationService;
  static late TownOrderManagementService townService;
  static late DatabaseService databaseService;
  static late PassengerService passengerService;
  static late RestaurantService restaurantService;
  static late BusOperatorService busOperatorService;
  static late HotelService hotelService;
  static late LiveLocationService liveLocationService;
  static late MenuManagementService menuService;
  static late DeliveryService deliveryService;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    print('🚀 [INIT] Initializing BusNStay services...');
    
    try {
      // Initialize Supabase
      print('🔐 [INIT] Connecting to Supabase...');
      await Supabase.initialize(
        url: 'https://ksepddxhvfkjfvnaervh.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzZXBkZHhodmZramZ2bmFlcnZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NjAzNTAsImV4cCI6MjA4NjIzNjM1MH0.PoqNk4G_AqVt560NTlcTJjOXU1ib8ZItzH5vtFd45-A',
      );
      final supabaseClient = Supabase.instance.client;
      print('✅ [INIT] Supabase connected successfully');

      // Initialize database
      databaseService = DatabaseService();
      print('✅ [INIT] Database service initialized');

      // Initialize notification service
      notificationService = RestaurantNotificationService(
        supabaseClient: supabaseClient,
      );
      print('✅ [INIT] Notification service initialized');

      // ============= WATI CONFIGURATION ✅ =============
      // WhatsApp notifications enabled via Wati
      RestaurantNotificationService.initializeWati(
        apiKey: 'wati_e4b6420d-a195-4dcb-afb8-e7a614387c50.vByJfCujf5OGX92okV8tBLLI7m71EvyNVip_AqDe7WRyCyYfqLnuM-iNf0BTWqpE44VAGryNw9lVXFoanhcQV0v217H5uydTBiRwNIDMueyqFwPS-k_G8Yh5ajv-uEsm',
        phoneNumberId: '27696469651', // +27696469651
      );
      
      print('📱 [WATI] Status: ${RestaurantNotificationService.isWatiConfigured() ? 'Configured ✅' : 'Not configured ⚠️'}');

      // Initialize town service
      townService = TownOrderManagementService(
        supabaseClient: supabaseClient,
      );
      print('✅ [INIT] Town management service initialized');

      // Initialize order service
      orderService = OrderManagementService(
        supabaseClient: supabaseClient,
        databaseService: databaseService,
        notificationService: notificationService,
        townService: townService,
      );
      print('✅ [INIT] Order management service initialized');

      // ============= PHASE 1: NEW SERVICES ✅ =============
      // Initialize Passenger Service (bookings + tracking)
      passengerService = PassengerService(supabase: supabaseClient);
      print('✅ [INIT] Passenger service initialized');

      // Initialize Restaurant Service (orders + WATI notifications)
      restaurantService = RestaurantService(
        supabase: supabaseClient,
        notificationService: notificationService,
      );
      print('✅ [INIT] Restaurant service initialized');

      // Initialize Bus Operator Service (journeys + seats)
      busOperatorService = BusOperatorService(supabase: supabaseClient);
      await busOperatorService.testConnection();

      // Initialize Hotel Service (bookings + rooms)
      hotelService = HotelService(supabase: supabaseClient);
      print('✅ [INIT] Hotel service initialized');

      // Initialize Live Location Service (GPS tracking)
      liveLocationService = LiveLocationService(supabase: supabaseClient);
      print('✅ [INIT] Live location service initialized');

      // Initialize Menu Management Service (pro menus + images)
      menuService = MenuManagementService(supabase: supabaseClient);
      print('✅ [INIT] Menu management service initialized');

      // Initialize Delivery Service (delivery agents)
      deliveryService = DeliveryService(supabase: supabaseClient);
      print('✅ [INIT] Delivery service initialized');

      _initialized = true;
      print('✅ [INIT] All services initialized successfully!');
    } catch (e) {
      print('❌ [ERROR] Failed to initialize services: $e');
      rethrow;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureDatabaseFactory();
  
  // Initialize all services
  await AppServices.initialize();
  
  runApp(const BusNStayApp());
}

void _configureDatabaseFactory() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      break;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      break;
  }
}

// ============ INLINE WIDGETS ============
class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  }) : super(key: key);

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.08),
                widget.color.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text(widget.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(widget.subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MiniStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _FrontDoorPill extends StatelessWidget {
  final String label;

  const _FrontDoorPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}


class BusNStayApp extends StatelessWidget {
  const BusNStayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'BusNStay',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // KFC-inspired crimson primary
      primaryColor: const Color(0xFFDC143C),
      secondaryHeaderColor: const Color(0xFFFD5E14),
      scaffoldBackgroundColor: brightness == Brightness.light 
        ? const Color(0xFFFAFAFA) 
        : const Color(0xFF1A1A2E),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light 
          ? const Color(0xFFFFFFFF) 
          : const Color(0xFF1A1A2E),
        foregroundColor: brightness == Brightness.light 
          ? const Color(0xFF000000) 
          : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFDC143C),
        brightness: brightness,
        secondary: const Color(0xFFFD5E14),
        tertiary: const Color(0xFF10B981),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (!state.isLoggedIn) {
          return const AuthScreen();
        }
        return _buildRoleScreen(state.user!.role, state);
      },
    );
  }

  Widget _buildRoleScreen(UserRole role, AppState state) {
    switch (role) {
      case UserRole.passenger:
        return PassengerExperiencePage(state: state);
      case UserRole.busOperator:
        return UpgradedBusOperatorDashboard(
          busOperatorId: state.user?.id ?? 'operator_001',
        );
      case UserRole.restaurantAdmin:
        return UpgradedRestaurantAdminDashboard(
          restaurantId: state.user?.id ?? 'restaurant_001',
        );
      case UserRole.deliveryAgent:
        return UpgradedDeliveryAgentDashboard(
          agentId: state.user?.id ?? 'agent_001',
        );
      case UserRole.hotelManager:
        return UpgradedHotelManagerDashboard(
          hotelId: state.user?.id ?? 'hotel_001',
        );
      case UserRole.platformAdmin:
        return AdminDashboard(state: state);
      default:
        return Scaffold(appBar: AppBar(title: const Text('BusNStay')), body: const Center(child: Text('Role not supported')));
    }
  }
}

// ============ AUTHENTICATION SCREEN ============
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _showForgotPassword = false;
  UserRole _selectedRole = UserRole.passenger;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show forgot password screen
    if (_showForgotPassword) {
      return ForgotPasswordScreen(
        onBackToLogin: () => setState(() => _showForgotPassword = false),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF5F5),
              Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16213E) : Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC143C).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/images/logo.jpg', width: 120, height: 120, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text('BusNStay', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDC143C),
                          letterSpacing: -0.5,
                        )),
                        const SizedBox(height: 12),
                        Text(
                          _isLogin ? 'Welcome Back' : 'Join Us',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin ? 'Select your role to continue' : 'Choose your role to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF111827), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withOpacity(0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live marketplace snapshot',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Food uploads, room inventory, bus movement tracking, and delivery countdowns are all surfaced from role dashboards.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _FrontDoorPill(label: 'Menu image uploads'),
                            _FrontDoorPill(label: 'Bus ETA tracking'),
                            _FrontDoorPill(label: 'Hotel room reports'),
                            _FrontDoorPill(label: 'Delivery earnings'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      _buildRoleCard('Passenger', Icons.person, UserRole.passenger),
                      _buildRoleCard('Bus Operator', Icons.directions_bus, UserRole.busOperator),
                      _buildRoleCard('Restaurant', Icons.restaurant, UserRole.restaurantAdmin),
                      _buildRoleCard('Delivery', Icons.local_shipping, UserRole.deliveryAgent),
                      _buildRoleCard('Hotel', Icons.hotel, UserRole.hotelManager),
                      _buildRoleCard('Admin', Icons.admin_panel_settings, UserRole.platformAdmin),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Credentials', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFD5E14).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.7),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.email, color: const Color(0xFFFD5E14).withOpacity(0.6), size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFD5E14).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.7),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.lock, color: const Color(0xFFFD5E14).withOpacity(0.6), size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _showForgotPassword = true),
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFFD5E14),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC143C), Color(0xFFFD5E14)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC143C).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final email = _emailController.text.isNotEmpty ? _emailController.text : 'user@busnstay.com';
                          context.read<AppState>().demoLogin(email, _selectedRole);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              _isLogin ? 'Login' : 'Register',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? "Don't have an account? " : 'Already have an account? ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            letterSpacing: 0.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin ? 'Register' : 'Login',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFD5E14),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String label, IconData icon, UserRole role) {
    final isSelected = _selectedRole == role;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFDC143C), Color(0xFFFD5E14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.06),
                      Colors.grey.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFDC143C)
                  : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFDC143C).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFFFD5E14).withOpacity(0.15),
                              const Color(0xFFFD5E14).withOpacity(0.05),
                            ],
                          ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFFD5E14).withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ PASSENGER DASHBOARD ============
class PassengerDashboard extends StatefulWidget {
  final AppState state;
  const PassengerDashboard({Key? key, required this.state}) : super(key: key);

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  int _tabIndex = 0;

  void _showPaymentModal(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaymentModal(
        title: title,
        onConfirm: (amount, method) {
          context.read<AppState>().addFunds(amount, method);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      drawer: _buildAppDrawer(context),
      body: _tabIndex == 0 ? _buildOverviewTab(context) : _tabIndex == 1 ? _buildWalletTab(context) : _tabIndex == 2 ? _buildRewardsTab(context) : _buildSettingsTab(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Drawer _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
            ),
            child: Consumer<AppState>(
              builder: (context, state, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      (state.user?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.user?.name ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.user?.email ?? 'email@example.com',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.pop(context);
              _showChangePasswordDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AppState>().logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordController.text == _confirmPasswordController.text &&
                  _newPasswordController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully!')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF3B82F6), const Color(0xFF3B82F6).withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${state.user?.name}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Member since March 15, 2024', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                MiniStatCard(
                  title: 'Balance',
                  value: 'K${state.wallet.balance.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                MiniStatCard(
                  title: 'Points',
                  value: '${state.loyalty.currentPoints}',
                  icon: Icons.star,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                MiniStatCard(
                  title: 'Tier',
                  value: state.loyalty.tierName,
                  icon: Icons.military_tech,
                  color: state.loyalty.tierColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Loyalty Tier Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: state.loyalty.tierProgress, minHeight: 8, color: state.loyalty.tierColor),
            ),
            const SizedBox(height: 8),
            Text('${(state.loyalty.tierProgress * 100).toStringAsFixed(0)}% to next tier', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            Text('Account Information', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildInfoRow('Name', state.user?.name ?? 'N/A'),
            _buildInfoRow('Email', state.user?.email ?? 'N/A'),
            _buildInfoRow('Phone', state.user?.phone ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTab(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF3B82F6), const Color(0xFF1E40AF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('K ${state.wallet.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Funds'),
                    onPressed: () => _showPaymentModal(context, 'Add Funds'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Transfer'),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.call_received),
                    label: const Text('Withdraw'),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...state.wallet.transactions.map((tx) => _buildTransactionTile(tx)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsTab(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.loyalty.tierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: state.loyalty.tierColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.military_tech, color: state.loyalty.tierColor, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.loyalty.tierName, style: TextStyle(color: state.loyalty.tierColor, fontWeight: FontWeight.bold)),
                      Text('${state.loyalty.currentPoints} / ${state.loyalty.currentPoints + state.loyalty.pointsToNextTier} points', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Available Rewards', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...state.loyalty.availableRewards.map((reward) => _buildRewardCard(context, reward, state)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Enable 2FA'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Email Notifications'),
            value: true,
            onChanged: (v) {},
          ),
          CheckboxListTile(
            title: const Text('SMS Notifications'),
            value: true,
            onChanged: (v) {},
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tx.color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(tx.icon, color: tx.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(tx.date.toString().split('.')[0], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Text('K${tx.amount.toStringAsFixed(2)}', style: TextStyle(color: tx.color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, LoyaltyReward reward, AppState state) {
    final canRedeem = state.loyalty.currentPoints >= reward.pointsCost && !reward.isRedeemed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.card_giftcard, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${reward.pointsCost} points', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          if (reward.isRedeemed)
            StatusBadge(label: 'Redeemed', color: const Color(0xFF10B981))
          else if (canRedeem)
            ElevatedButton(onPressed: () => context.read<AppState>().redeemReward(reward.id), child: const Text('Redeem'))
          else
            Text('Locked', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============ BUS OPERATOR DASHBOARD ============
class BusOperatorDashboard extends StatefulWidget {
  final AppState state;
  const BusOperatorDashboard({Key? key, required this.state}) : super(key: key);

  @override
  State<BusOperatorDashboard> createState() => _BusOperatorDashboardState();
}

class _BusOperatorDashboardState extends State<BusOperatorDashboard> {
  late BusOperatorService _busService;
  List<Map<String, dynamic>> _journeys = [];
  List<Map<String, dynamic>> _buses = [];
  double _todayRevenue = 0;
  bool _loading = true;
  late RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    _busService = AppServices.busOperatorService;
    _loadData();
    _subscribeToUpdates();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      
      // Load buses
      _buses = await _busService.getBuses('operator_001'); // Replace with real operator ID
      
      // Load journeys
      _journeys = await _busService.getActiveJourneys('operator_001');
      
      // Load today's revenue
      _todayRevenue = await _busService.getOperatorRevenue('operator_001', DateTime.now());
      
      setState(() => _loading = false);
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  void _subscribeToUpdates() {
    if (_journeys.isNotEmpty) {
      _subscription = _busService.subscribeToJourney(_journeys.first['id']);
    }
  }

  @override
  void dispose() {
    _subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Operator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFFD5E14)),
            tooltip: 'Pro Dashboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UpgradedBusOperatorDashboard(busOperatorId: 'operator_001'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const UpgradedBusOperatorDashboard(busOperatorId: 'operator_001'),
            ));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Pro View'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StatCard(
                    title: 'Total Buses',
                    value: '${_buses.length}',
                    icon: Icons.directions_bus,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'Active Journeys',
                    value: '${_journeys.length}',
                    icon: Icons.map,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'Revenue Today',
                    value: 'K${_todayRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'Bookings',
                    value: _journeys.fold<int>(0, (sum, j) => sum + ((j['bookings'] as List?)?.length ?? 0)).toString(),
                    icon: Icons.pending_actions,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 20),
                  Text('Active Journeys', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._journeys.map((j) => _buildJourneyCard(context, j)).toList(),
                  if (_journeys.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No active journeys',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewJourneyDialog(context),
        tooltip: 'Create Journey',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, Map<String, dynamic> j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        color: Colors.grey.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${j['origin']} → ${j['destination']}', 
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(j['journey_date'] ?? 'N/A',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('K${j['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 16)),
                  Text(j['status'] ?? 'active', 
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.green)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seats Booked', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                    Text('${j['total_seats'] - j['available_seats']}/${j['total_seats']}', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (j['total_seats'] - j['available_seats']) / j['total_seats'],
                    minHeight: 6,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateJourneyStatus(j['id'], 'active'),
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateJourneyStatus(j['id'], 'completed'),
                  child: const Text('Complete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateJourneyStatus(String journeyId, String status) async {
    final success = await _busService.updateJourneyStatus(journeyId, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Journey updated to $status ✅')),
      );
      _loadData();
    }
  }

  void _showNewJourneyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Journey'),
        content: const Text('Feature coming soon! Use mobile app to create journeys.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ============ RESTAURANT ADMIN DASHBOARD ============
class RestaurantAdminDashboard extends StatefulWidget {
  final AppState state;
  const RestaurantAdminDashboard({Key? key, required this.state}) : super(key: key);

  @override
  State<RestaurantAdminDashboard> createState() => _RestaurantAdminDashboardState();
}

class _RestaurantAdminDashboardState extends State<RestaurantAdminDashboard> {
  int _tabIndex = 0;
  bool _isOpen = true;
  late RestaurantService _restaurantService;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _menuItems = [];
  bool _loading = true;
  late RealtimeChannel _orderSubscription;

  @override
  void initState() {
    super.initState();
    _restaurantService = AppServices.restaurantService;
    _loadData();
    _subscribeToOrders();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      
      _pendingOrders = await _restaurantService.getPendingOrders('restaurant_001');
      _menuItems = await _restaurantService.getMenuItems('restaurant_001');
      
      setState(() => _loading = false);
    } catch (e) {
      print('❌ Error loading restaurant data: $e');
      setState(() => _loading = false);
    }
  }

  void _subscribeToOrders() {
    _orderSubscription = _restaurantService.subscribeToOrders('restaurant_001');
  }

  @override
  void dispose() {
    _orderSubscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFFD5E14)),
            tooltip: 'Pro Dashboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UpgradedRestaurantAdminDashboard(restaurantId: 'restaurant_001'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const UpgradedRestaurantAdminDashboard(restaurantId: 'restaurant_001'),
            ));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Pro View'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Manager Dashboard', 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isOpen ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isOpen ? const Color(0xFF10B981) : Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _isOpen = !_isOpen),
                            child: Text(
                              _isOpen ? '🟢 Open' : '🔴 Closed',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isOpen ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MiniStatCard(
                            title: 'Pending',
                            value: '${_pendingOrders.length}',
                            icon: Icons.receipt,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MiniStatCard(
                            title: 'Menu Items',
                            value: '${_menuItems.length}',
                            icon: Icons.restaurant_menu,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tabIndex == 0 ? const Color(0xFF3B82F6) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Orders',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _tabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _tabIndex == 0 ? const Color(0xFF3B82F6) : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Menu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _tabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_tabIndex == 0) ...[
                      Text('Pending Orders', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._pendingOrders.map((o) => _buildOrderCard(context, o)).toList(),
                      if (_pendingOrders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text('No pending orders', 
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          ),
                        ),
                    ] else ...[
                      Text('Menu Items', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._menuItems.map((m) => _buildMenuItemTile(context, m)).toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        color: Colors.grey.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${o['id']?.toString().substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              StatusBadge(label: o['status'] ?? 'pending', color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Customer: ${o['customer_name'] ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptOrder(o),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectOrder(o),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _markReady(o),
                  child: const Text('Ready'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemTile(BuildContext context, Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${m['category'] ?? 'N/A'} • K${m['price']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          InkWell(
            onTap: () => _toggleItemAvailability(m),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: (m['is_available'] ?? false)
                    ? LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.2), Colors.transparent])
                    : LinearGradient(colors: [Colors.grey.withOpacity(0.2), Colors.transparent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                (m['is_available'] ?? false) ? Icons.check_circle : Icons.cancel,
                color: (m['is_available'] ?? false) ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptOrder(Map<String, dynamic> order) async {
    final success = await _restaurantService.acceptOrder(
      order['id'],
      order['customer_phone'] ?? '+27696469651',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted & customer notified ✅')),
      );
      _loadData();
    }
  }

  void _rejectOrder(Map<String, dynamic> order) async {
    final success = await _restaurantService.rejectOrder(
      order['id'],
      order['customer_phone'] ?? '+27696469651',
      'Item not available',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order declined & customer notified')),
      );
      _loadData();
    }
  }

  void _markReady(Map<String, dynamic> order) async {
    final success = await _restaurantService.markOrderReady(
      order['id'],
      order['customer_phone'] ?? '+27696469651',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked ready & customer notified 🎉')),
      );
      _loadData();
    }
  }

  void _toggleItemAvailability(Map<String, dynamic> item) async {
    final newAvailability = !(item['is_available'] ?? false);
    final success = await _restaurantService.updateMenuItemAvailability(
      item['id'],
      newAvailability,
    );
    if (success) {
      _loadData();
    }
  }
}

// ============ DELIVERY AGENT DASHBOARD ============
class DeliveryAgentDashboard extends StatefulWidget {
  final AppState state;
  const DeliveryAgentDashboard({Key? key, required this.state}) : super(key: key);

  @override
  State<DeliveryAgentDashboard> createState() => _DeliveryAgentDashboardState();
}

class _DeliveryAgentDashboardState extends State<DeliveryAgentDashboard> {
  bool _isOnline = false;
  late DeliveryService _deliveryService;
  List<Map<String, dynamic>> _availableDeliveries = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  bool _loading = true;
  double _todayEarnings = 0;
  late RealtimeChannel _deliverySubscription;

  @override
  void initState() {
    super.initState();
    _deliveryService = AppServices.deliveryService;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      
      if (_isOnline) {
        _availableDeliveries = await _deliveryService.getAvailableDeliveries();
        _activeDeliveries = await _deliveryService.getAgentDeliveries('agent_001');
        _todayEarnings = await _deliveryService.getAgentEarnings('agent_001', DateTime.now());
        _subscribeToDeliveries();
      }
      
      setState(() => _loading = false);
    } catch (e) {
      print('❌ Error loading delivery data: $e');
      setState(() => _loading = false);
    }
  }

  void _subscribeToDeliveries() {
    if (_activeDeliveries.isNotEmpty) {
      _deliverySubscription = _deliveryService.subscribeToDelivery(_activeDeliveries.first['id']);
    }
  }

  @override
  void dispose() {
    _deliverySubscription.unsubscribe();
    super.dispose();
  }

  void _toggleOnline() async {
    setState(() => _isOnline = !_isOnline);
    
    try {
      if (_isOnline) {
        await _deliveryService.setAgentOnline('agent_001', true);
        _loadData();
      } else {
        await _deliveryService.setAgentOnline('agent_001', false);
        setState(() {
          _availableDeliveries = [];
          _activeDeliveries = [];
        });
      }
    } catch (e) {
      print('❌ Error toggling online status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Dashboard', 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: _toggleOnline,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isOnline ? const Color(0xFF10B981).withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isOnline ? const Color(0xFF10B981) : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _isOnline ? '🟢 Online' : '🔴 Offline',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isOnline ? const Color(0xFF10B981) : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isOnline) ...[
                      Row(
                        children: [
                          Expanded(
                            child: MiniStatCard(
                              title: 'Available',
                              value: '${_availableDeliveries.length}',
                              icon: Icons.local_shipping,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MiniStatCard(
                              title: 'Active',
                              value: '${_activeDeliveries.length}',
                              icon: Icons.delivery_dining,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MiniStatCard(
                              title: 'Earnings',
                              value: 'K${_todayEarnings.toStringAsFixed(0)}',
                              icon: Icons.attach_money,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Available Deliveries', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._availableDeliveries.map((d) => _buildDeliveryCard(context, d)).toList(),
                      if (_availableDeliveries.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text('No available deliveries',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_activeDeliveries.isNotEmpty) ...[
                        Text('Active Deliveries', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ..._activeDeliveries.map((d) => _buildActiveDeliveryCard(context, d)).toList(),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.withOpacity(0.1),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'Go online to see available deliveries',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _toggleOnline,
                              child: const Text('Go Online'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        color: Colors.grey.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${d['id']?.toString().substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
              Text('K${d['fee']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  d['pickup_address'] ?? 'N/A',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  d['delivery_address'] ?? 'N/A',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${d['distance']} km • ${d['customer_name'] ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _acceptDelivery(d),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(BuildContext context, Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8B5CF6)),
        color: const Color(0xFF8B5CF6).withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${d['id']?.toString().substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              StatusBadge(label: d['status'] ?? 'in-transit', color: const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 8),
          Text('To: ${d['delivery_address'] ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _markDelivered(d),
                  child: const Text('Delivered'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancelDelivery(d),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptDelivery(Map<String, dynamic> delivery) async {
    final success = await _deliveryService.acceptDelivery(
      delivery['id'],
      'agent_001',
      delivery['customer_phone'] ?? '+27696469651',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery accepted! 🚗')),
      );
      _loadData();
    }
  }

  void _markDelivered(Map<String, dynamic> delivery) async {
    final success = await _deliveryService.markDelivered(
      delivery['id'],
      delivery['customer_phone'] ?? '+27696469651',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery completed! ✅')),
      );
      _loadData();
    }
  }

  void _cancelDelivery(Map<String, dynamic> delivery) async {
    final success = await _deliveryService.cancelDelivery(
      delivery['id'],
      delivery['customer_phone'] ?? '+27696469651',
      'Unable to complete',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery cancelled')),
      );
      _loadData();
    }
  }
}

// ============ HOTEL MANAGER DASHBOARD ============
class HotelManagerDashboard extends StatefulWidget {
  final AppState state;
  const HotelManagerDashboard({Key? key, required this.state}) : super(key: key);

  @override
  State<HotelManagerDashboard> createState() => _HotelManagerDashboardState();
}

class _HotelManagerDashboardState extends State<HotelManagerDashboard> {
  int _tabIndex = 0;
  bool _isOpen = true;
  late HotelService _hotelService;
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _confirmedBookings = [];
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  double _occupancyRate = 0;
  double _todayRevenue = 0;
  late RealtimeChannel _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _hotelService = AppServices.hotelService;
    _loadData();
    _subscribeToBookings();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      
      _pendingBookings = await _hotelService.getPendingBookings('hotel_001');
      _confirmedBookings = await _hotelService.getConfirmedBookings('hotel_001', DateTime.now());
      _rooms = await _hotelService.getRooms('hotel_001');
      _occupancyRate = await _hotelService.getOccupancyRate('hotel_001');
      _todayRevenue = await _hotelService.getTodayRevenue('hotel_001');
      
      setState(() => _loading = false);
    } catch (e) {
      print('❌ Error loading hotel data: $e');
      setState(() => _loading = false);
    }
  }

  void _subscribeToBookings() {
    _bookingSubscription = _hotelService.subscribeToBookings('hotel_001');
  }

  @override
  void dispose() {
    _bookingSubscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF14B8A6)),
            tooltip: 'Pro Dashboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UpgradedHotelManagerDashboard(hotelId: 'hotel_001'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const UpgradedHotelManagerDashboard(hotelId: 'hotel_001'),
            ));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Pro View'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hotel Manager',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isOpen ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isOpen ? const Color(0xFF10B981) : Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _isOpen = !_isOpen),
                            child: Text(
                              _isOpen ? '🟢 Open' : '🔴 Closed',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isOpen ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MiniStatCard(
                            title: 'Occupancy',
                            value: '${_occupancyRate.toStringAsFixed(0)}%',
                            icon: Icons.hotel,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MiniStatCard(
                            title: 'Pending',
                            value: '${_pendingBookings.length}',
                            icon: Icons.pending_actions,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MiniStatCard(
                            title: 'Today Revenue',
                            value: 'K${_todayRevenue.toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tabIndex == 0 ? const Color(0xFF3B82F6) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Bookings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _tabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _tabIndex == 0 ? const Color(0xFF3B82F6) : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Rooms',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _tabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_tabIndex == 0) ...[
                      if (_pendingBookings.isNotEmpty) ...[
                        Text('Pending Confirmations',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFFF59E0B))),
                        const SizedBox(height: 12),
                        ..._pendingBookings.map((b) => _buildBookingCard(context, b, isPending: true)).toList(),
                        const SizedBox(height: 20),
                      ],
                      Text("Today's Check-ins",
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._confirmedBookings.map((b) => _buildBookingCard(context, b, isPending: false)).toList(),
                      if (_confirmedBookings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text('No bookings for today',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          ),
                        ),
                    ] else ...[
                      Text('Available Rooms',
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._rooms.map((r) => _buildRoomTile(context, r)).toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> b, {bool isPending = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        color: isPending ? const Color(0xFFF59E0B).withOpacity(0.05) : Colors.grey.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${b['room_number']} - ${b['room_type'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(b['guest_name'] ?? 'N/A',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              StatusBadge(
                label: b['status'] ?? 'pending',
                color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF14B8A6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${b['nights']} nights • ${b['guests']} guest(s) • K${b['total_price']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmBooking(b),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectBooking(b),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _checkIn(b),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              child: const Text('Check In'),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, Map<String, dynamic> r) {
    final isAvailable = r['status'] == 'available';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0xFF10B981).withOpacity(0.15) : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.hotel,
                color: isAvailable ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['number'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${r['type'] ?? 'N/A'} • K${r['price_per_night']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          StatusBadge(
            label: isAvailable ? 'Available' : 'Occupied',
            color: isAvailable ? const Color(0xFF10B981) : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _confirmBooking(Map<String, dynamic> booking) async {
    final success = await _hotelService.confirmBooking(
      booking['id'],
      booking['guest_phone'] ?? '+27696469651',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed & guest notified ✅')),
      );
      _loadData();
    }
  }

  void _rejectBooking(Map<String, dynamic> booking) async {
    final success = await _hotelService.rejectBooking(
      booking['id'],
      booking['guest_phone'] ?? '+27696469651',
      'Room unavailable',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected & guest notified')),
      );
      _loadData();
    }
  }

  void _checkIn(Map<String, dynamic> booking) async {
    final success = await _hotelService.checkIn(
      booking['id'],
      booking['guest_phone'] ?? '+27696469651',
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guest checked in! Welcome 🎉')),
      );
      _loadData();
    }
  }
}

// ============ ADMIN DASHBOARD ============
class AdminDashboard extends StatefulWidget {
  final AppState state;
  const AdminDashboard({Key? key, required this.state}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Admin'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppState>().logout())],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.approval), label: 'Approvals'),
          NavigationDestination(icon: Icon(Icons.gps_fixed), label: 'Tracking'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: MiniStatCard(title: 'Users', value: '12K', icon: Icons.people, color: const Color(0xFF3B82F6))),
                const SizedBox(width: 12),
                Expanded(child: MiniStatCard(title: 'Revenue', value: 'K2.4M', icon: Icons.attach_money, color: const Color(0xFF10B981))),
                const SizedBox(width: 12),
                Expanded(child: MiniStatCard(title: 'Transactions', value: '342', icon: Icons.swap_horiz, color: const Color(0xFFF59E0B))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabIndex == 0 ? const Color(0xFF3B82F6) : Colors.transparent, width: 2))),
                      child: Text('Approvals', textAlign: TextAlign.center, style: TextStyle(fontWeight: _tabIndex == 0 ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.transparent, width: 2))),
                      child: Text('Tracking', textAlign: TextAlign.center, style: TextStyle(fontWeight: _tabIndex == 1 ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tabIndex == 0) ...[
              Text('Pending Approvals', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildApprovalCard('Restaurant: Nshima Palace', 'John Doe', 'restaurant'),
              _buildApprovalCard('Delivery: Urban Couriers', 'Grace Tembo', 'delivery'),
              _buildApprovalCard('Hotel: Radisson Blu', 'Admin User', 'hotel'),
            ] else ...[
              Text('Fleet Operations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildTrackingCard('BUS-001', 'Lusaka', 'Active', '45/52 passengers'),
              _buildTrackingCard('BUS-002', 'Ndola', 'Active', '35/52 passengers'),
              _buildTrackingCard('BUS-003', 'Kitwe', 'Maintenance', '- passengers'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(String name, String submittedBy, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Submitted by: $submittedBy', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(onPressed: () {}, child: const Text('Review')),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(String fleet, String location, String status, String info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.directions_bus, color: Color(0xFF8B5CF6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fleet, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$location ÔÇó $info', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          StatusBadge(label: status, color: status == 'Active' ? const Color(0xFF10B981) : Colors.orange),
        ],
      ),
    );
  }
}
