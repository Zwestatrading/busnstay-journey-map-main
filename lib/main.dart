import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user_model.dart';
import 'models/wallet_model.dart';
import 'models/order_model.dart';
import 'models/booking_model.dart';
import 'models/journey_model.dart';
import 'models/delivery_model.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'services/order_management_service.dart';
import 'services/restaurant_notification_service.dart';
import 'services/town_order_management_service.dart';
import 'services/passenger_service.dart';
import 'services/restaurant_service.dart';
import 'services/bus_operator_service.dart';
import 'widgets/payment_modal.dart';
import 'widgets/status_badge.dart';
import 'pages/forgot_password_page.dart';

// ============ APP SERVICES SINGLETON ============
class AppServices {
  static late OrderManagementService orderService;
  static late RestaurantNotificationService notificationService;
  static late TownOrderManagementService townService;
  static late DatabaseService databaseService;
  static late PassengerService passengerService;
  static late RestaurantService restaurantService;
  static late BusOperatorService busOperatorService;

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
  
  // Initialize all services
  await AppServices.initialize();
  
  runApp(const BusNStayApp());
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
      // Vibrant primary orange (like KFC)
      primaryColor: const Color(0xFFE74C3C),
      // Colorful secondary
      secondaryHeaderColor: const Color(0xFF9B59B6),
      scaffoldBackgroundColor: brightness == Brightness.light 
        ? const Color(0xFFFAFAFA) 
        : const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light 
          ? const Color(0xFFFFFFFF) 
          : const Color(0xFF1F2937),
        foregroundColor: brightness == Brightness.light 
          ? const Color(0xFF000000) 
          : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE74C3C),
        brightness: brightness,
        secondary: const Color(0xFFFF9800),
        tertiary: const Color(0xFF4CAF50),
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
        return PassengerDashboard(state: state);
      case UserRole.busOperator:
        return BusOperatorDashboard(state: state);
      case UserRole.restaurantAdmin:
        return RestaurantAdminDashboard(state: state);
      case UserRole.deliveryAgent:
        return DeliveryAgentDashboard(state: state);
      case UserRole.hotelManager:
        return HotelManagerDashboard(state: state);
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
              Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
              Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
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
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                          color: const Color(0xFF3B82F6),
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
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                        prefixIcon: Icon(Icons.email, color: const Color(0xFF3B82F6).withOpacity(0.6), size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                        prefixIcon: Icon(Icons.lock, color: const Color(0xFF3B82F6).withOpacity(0.6), size: 20),
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
                            color: const Color(0xFF3B82F6),
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
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
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
                              color: const Color(0xFF3B82F6),
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
      cursor: SystemMouseCursor.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
                  ? const Color(0xFF3B82F6)
                  : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                              const Color(0xFF3B82F6).withOpacity(0.15),
                              const Color(0xFF3B82F6).withOpacity(0.05),
                            ],
                          ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF3B82F6).withOpacity(0.7),
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
class BusOperatorDashboard extends StatelessWidget {
  final AppState state;
  const BusOperatorDashboard({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Operator'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppState>().logout())],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StatCard(title: 'Total Buses', value: '5', icon: Icons.directions_bus, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            StatCard(title: 'Active Journeys', value: '3', icon: Icons.map, color: const Color(0xFF10B981)),
            const SizedBox(height: 12),
            StatCard(title: 'Revenue Today', value: 'K45,000', icon: Icons.attach_money, color: const Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            StatCard(title: 'Bookings Pending', value: '8', icon: Icons.pending_actions, color: const Color(0xFF8B5CF6)),
            const SizedBox(height: 20),
            ...state.getDemoJourneys().map((j) => _buildJourneyCard(context, j)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, BusJourney j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text('${j.origin} ÔåÆ ${j.destination}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text('K${j.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 8),
          Text('${j.bookedSeats}/${j.totalSeats} seats booked', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: j.bookedSeats / j.totalSeats, minHeight: 6)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Manager'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppState>().logout())],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Manager Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  OpenClosedToggle(isOpen: _isOpen, onChanged: (v) => setState(() => _isOpen = v)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: MiniStatCard(title: 'Orders', value: '24', icon: Icons.receipt, color: const Color(0xFFF59E0B))),
                  const SizedBox(width: 12),
                  Expanded(child: MiniStatCard(title: 'Revenue', value: 'K125K', icon: Icons.attach_money, color: const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: MiniStatCard(title: 'Menu', value: '42', icon: Icons.restaurant_menu, color: const Color(0xFF3B82F6))),
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
                          border: Border(bottom: BorderSide(color: _tabIndex == 0 ? const Color(0xFF3B82F6) : Colors.transparent, width: 2)),
                        ),
                        child: Text('Orders', textAlign: TextAlign.center, style: TextStyle(fontWeight: _tabIndex == 0 ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.transparent, width: 2)),
                        ),
                        child: Text('Menu', textAlign: TextAlign.center, style: TextStyle(fontWeight: _tabIndex == 1 ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_tabIndex == 0) ...[
                Text('Pending Orders', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...state.getDemoOrders().map((o) => _buildOrderCard(context, o)).toList(),
              ] else ...[
                Text('Menu Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...state.getDemoMenuItems().map((m) => _buildMenuItemTile(context, m)).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, FoodOrder o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.id, style: const TextStyle(fontWeight: FontWeight.w600)),
              StatusBadge(label: o.statusLabel, color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Customer: ${o.customerName}', style: Theme.of(context).textTheme.bodySmall),
          ...o.items.map((i) => Text('  ÔÇó ${i.quantity}x ${i.name} - K${(i.total).toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey))).toList(),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Accept')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Decline')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemTile(BuildContext context, MenuItem m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${m.category} ÔÇó K${m.price} ÔÇó ${m.prepTimeMinutes}min', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Checkbox(value: m.isAvailable, onChanged: (v) {}),
        ],
      ),
    );
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
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Agent'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppState>().logout())],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => setState(() => _isOnline = !_isOnline),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isOnline ? const Color(0xFF10B981).withOpacity(0.15) : Color.fromARGB(255, 239, 68, 68).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_isOnline ? '­ƒƒó Online' : '­ƒö┤ Offline', style: TextStyle(fontWeight: FontWeight.w600, color: _isOnline ? const Color(0xFF10B981) : Color.fromARGB(255, 239, 68, 68))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: MiniStatCard(title: 'Today', value: '12', icon: Icons.local_shipping, color: const Color(0xFF3B82F6))),
                  const SizedBox(width: 12),
                  Expanded(child: MiniStatCard(title: 'Earnings', value: 'K525', icon: Icons.attach_money, color: const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: MiniStatCard(title: 'Rating', value: '4.8Ôÿà', icon: Icons.star, color: const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 24),
              if (_isOnline) ...[
                Text('Available Deliveries', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...state.getDemoDeliveries().map((d) => _buildDeliveryCard(context, d)).toList(),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.withOpacity(0.1)),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Go online to see available deliveries', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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

  Widget _buildDeliveryCard(BuildContext context, DeliveryJob d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d.id, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
              Text('K${d.fee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(d.pickupAddress, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)))],
          ),
          const SizedBox(height: 4),
          Row(
            children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(d.deliveryAddress, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)))],
          ),
          const SizedBox(height: 8),
          Text('${d.distance} km ÔÇó ${d.customerName}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () {}, child: const Text('Accept'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6))),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Manager'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppState>().logout())],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hotel Manager', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  OpenClosedToggle(isOpen: _isOpen, onChanged: (v) => setState(() => _isOpen = v)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: MiniStatCard(title: 'Rooms', value: '8/25', icon: Icons.hotel, color: const Color(0xFF14B8A6))),
                  const SizedBox(width: 12),
                  Expanded(child: MiniStatCard(title: 'Check-ins', value: '5', icon: Icons.login, color: const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: MiniStatCard(title: 'Revenue', value: 'K1.2M', icon: Icons.attach_money, color: const Color(0xFF10B981))),
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
                        child: Text('Bookings', textAlign: TextAlign.center, style: TextStyle(fontWeight: _tabIndex == 0 ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabIndex == 1 ? const Color(0xFF3B82F6) : Colors.transparent, width: 2))),
                        child: Text('Rooms', textAlign: TextAlign.center, style: TextStyle(fontWeight: _tabIndex == 1 ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_tabIndex == 0) ...[
                Text("Today's Bookings", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...state.getDemoBookings().map((b) => _buildBookingCard(context, b)).toList(),
              ] else ...[
                Text('Available Rooms', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...state.getDemoRooms().map((r) => _buildRoomTile(context, r)).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, HotelBooking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${b.roomNumber} - ${b.roomType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(b.guestName, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              StatusBadge(label: b.statusLabel, color: const Color(0xFF14B8A6)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${b.nights} nights ÔÇó ${b.guests} guest(s) ÔÇó K${b.totalPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Confirm'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981))),
              if (b.status == BookingStatus.confirmed) ElevatedButton(onPressed: () {}, child: const Text('Check In'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, HotelRoom r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: r.isAvailable ? const Color(0xFF10B981).withOpacity(0.15) : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(Icons.hotel, color: r.isAvailable ? const Color(0xFF10B981) : Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.number, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${r.type} ÔÇó K${r.pricePerNight} per night', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          StatusBadge(label: r.isAvailable ? 'Available' : 'Occupied', color: r.isAvailable ? const Color(0xFF10B981) : Colors.grey),
        ],
      ),
    );
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
