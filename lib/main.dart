import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/user_model.dart';
import 'models/wallet_model.dart';
import 'models/order_model.dart';
import 'models/booking_model.dart';
import 'models/journey_model.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'services/order_management_service.dart';
import 'services/restaurant_notification_service.dart';
import 'services/town_order_management_service.dart';
import 'widgets/payment_modal.dart';
import 'widgets/status_badge.dart';

// ============ APP SERVICES SINGLETON ============
class AppServices {
  static late OrderManagementService orderService;
  static late RestaurantNotificationService notificationService;
  static late TownOrderManagementService townService;
  static late DatabaseService databaseService;

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
class StatCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
      primaryColor: const Color(0xFF3B82F6),
      scaffoldBackgroundColor: brightness == Brightness.light ? Colors.white : const Color(0xFF1F2937),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light ? const Color(0xFF3B82F6) : const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: brightness,
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/images/logo.jpg', width: 120, height: 120, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Text('BusNStay', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                const SizedBox(height: 8),
                Text(_isLogin ? 'Welcome Back' : 'Create Account', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 32),
                Text('Select your role:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildRoleCard('Passenger', Icons.person, UserRole.passenger),
                    _buildRoleCard('Bus Operator', Icons.directions_bus, UserRole.busOperator),
                    _buildRoleCard('Restaurant', Icons.restaurant, UserRole.restaurantAdmin),
                    _buildRoleCard('Delivery Agent', Icons.local_shipping, UserRole.deliveryAgent),
                    _buildRoleCard('Hotel Manager', Icons.hotel, UserRole.hotelManager),
                    _buildRoleCard('Admin', Icons.admin_panel_settings, UserRole.platformAdmin),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final email = _emailController.text.isNotEmpty ? _emailController.text : 'user@busnstay.com';
                      context.read<AppState>().demoLogin(email, _selectedRole);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? "Don't have an account? " : 'Already have an account? '),
                    GestureDetector(
                      onTap: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Register' : 'Login', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String label, IconData icon, UserRole role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
          ],
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
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppState>().logout()),
        ],
      ),
      body: _tabIndex == 0 ? _buildOverviewTab(context) : _tabIndex == 1 ? _buildWalletTab(context) : _tabIndex == 2 ? _buildRewardsTab(context) : _buildSettingsTab(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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
