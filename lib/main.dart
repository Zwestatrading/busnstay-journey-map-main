import 'package:flutter/material.dart';

void main() {
  runApp(const BusNStayApp());
}

// User role enum
enum UserRole {
  passenger,
  busOperator,
  restaurantAdmin,
  deliveryAgent,
  hotelManager,
  platformAdmin,
  guest
}

class BusNStayApp extends StatefulWidget {
  const BusNStayApp({Key? key}) : super(key: key);

  @override
  State<BusNStayApp> createState() => _BusNStayAppState();
}

class _BusNStayAppState extends State<BusNStayApp> {
  UserRole? _userRole;
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusNStay',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: const Color(0xFF1F2937),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: _isLoggedIn 
          ? _buildRoleBasedHome() 
          : AuthScreen(
              onLoginSuccess: (role) {
                setState(() {
                  _userRole = role;
                  _isLoggedIn = true;
                });
              },
            ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildRoleBasedHome() {
    switch (_userRole) {
      case UserRole.passenger:
        return PassengerHomeScreen(
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _userRole = null;
            });
          },
        );
      case UserRole.busOperator:
        return BusOperatorDashboard(
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _userRole = null;
            });
          },
        );
      case UserRole.restaurantAdmin:
        return RestaurantAdminDashboard(
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _userRole = null;
            });
          },
        );
      case UserRole.deliveryAgent:
        return DeliveryAgentDashboard(
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _userRole = null;
            });
          },
        );
      case UserRole.hotelManager:
        return HotelManagerDashboard(
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _userRole = null;
            });
          },
        );
      case UserRole.platformAdmin:
        return AdminDashboard(
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _userRole = null;
            });
          },
        );
      default:
        return const HomeScreen();
    }
  }
}

// ============ AUTHENTICATION SCREEN ============
class AuthScreen extends StatefulWidget {
  final Function(UserRole) onLoginSuccess;

  const AuthScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  UserRole _selectedRole = UserRole.passenger;

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
                Text(
                  'BusNStay',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),

                // Role Selection
                Text(
                  'Select your role:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildRoleCard(
                      'Passenger',
                      Icons.person,
                      UserRole.passenger,
                    ),
                    _buildRoleCard(
                      'Bus Operator',
                      Icons.directions_bus,
                      UserRole.busOperator,
                    ),
                    _buildRoleCard(
                      'Restaurant',
                      Icons.restaurant,
                      UserRole.restaurantAdmin,
                    ),
                    _buildRoleCard(
                      'Delivery Agent',
                      Icons.local_shipping,
                      UserRole.deliveryAgent,
                    ),
                    _buildRoleCard(
                      'Hotel Manager',
                      Icons.hotel,
                      UserRole.hotelManager,
                    ),
                    _buildRoleCard(
                      'Admin',
                      Icons.admin_panel_settings,
                      UserRole.platformAdmin,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Auth Fields
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),

                // Login/Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onLoginSuccess(_selectedRole);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isLogin ? 'Login' : 'Register',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle Login/Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin ? 'Register' : 'Login',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PASSENGER HOME SCREEN ============
class PassengerHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const PassengerHomeScreen({Key? key, required this.onLogout})
      : super(key: key);

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusNStay - Passenger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Traveler!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your next adventure',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Services Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildServiceCard(
                    context,
                    icon: Icons.directions_bus,
                    title: 'Book Bus',
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.restaurant,
                    title: 'Order Food',
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.hotel,
                    title: 'Book Hotel',
                    color: const Color(0xFF10B981),
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.local_shipping,
                    title: 'Track Delivery',
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Bookings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Bookings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            color: Color(0xFF3B82F6)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lagos → Ibadan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge),
                              Text('Tomorrow, 2:00 PM',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        ),
                        const Text('₦2,500',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature available!')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ============ BUS OPERATOR DASHBOARD ============
class BusOperatorDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  const BusOperatorDashboard({Key? key, required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Operator Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDashboardCard(
            context,
            title: 'Total Buses',
            value: '5',
            icon: Icons.directions_bus,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            context,
            title: 'Active Journeys',
            value: '3',
            icon: Icons.map,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            context,
            title: 'Revenue Today',
            value: '₦45,000',
            icon: Icons.attach_money,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            context,
            title: 'Pending Bookings',
            value: '8',
            icon: Icons.pending_actions,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create New Journey'),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodySmall),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ RESTAURANT ADMIN DASHBOARD ============
class RestaurantAdminDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  const RestaurantAdminDashboard({Key? key, required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            context,
            'Total Orders',
            '24',
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            'Revenue',
            '₦125,000',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            'Active Menu Items',
            '42',
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 24),
          const Text('Pending Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildOrderTile(context, 'Order #001', 'Jollof Rice + Chicken', '2 items'),
          const SizedBox(height: 8),
          _buildOrderTile(context, 'Order #002', 'Pepper Soup + Bread', '3 items'),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(
      BuildContext context, String orderId, String items, String count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children:  [
          const Icon(Icons.receipt, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderId, style: Theme.of(context).textTheme.labelLarge),
                Text(items, style: Theme.of(context).textTheme.bodySmall),
                Text(count, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

// ============ DELIVERY AGENT DASHBOARD ============
class DeliveryAgentDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  const DeliveryAgentDashboard({Key? key, required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Agent'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricCard(context, 'Deliveries Today', '12', Colors.blue),
          const SizedBox(height: 12),
          _buildMetricCard(context, 'Earnings', '₦18,500', Colors.green),
          const SizedBox(height: 12),
          _buildMetricCard(context, 'Rating', '4.8/5.0', Colors.amber),
          const SizedBox(height: 24),
          const Text('Active Deliveries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDeliveryCard(context, 'Order #101',
              'Restaurant to Home', '2 km away'),
          const SizedBox(height: 8),
          _buildDeliveryCard(context, 'Order #102',
              'Hotel to Airport', '5 km away'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Icon(Icons.local_shipping, size: 40, color: color),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(
      BuildContext context, String orderId, String route, String distance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(orderId, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(route, style: Theme.of(context).textTheme.bodySmall),
          Text(distance,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: () {}, child: const Text('Start Delivery')),
        ],
      ),
    );
  }
}

// ============ HOTEL MANAGER DASHBOARD ============
class HotelManagerDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  const HotelManagerDashboard({Key? key, required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context, 'Available Rooms', '8/25', Colors.teal),
          const SizedBox(height: 12),
          _buildInfoCard(context, 'Check-ins Today', '5', Colors.orange),
          const SizedBox(height: 12),
          _buildInfoCard(context, 'Revenue This Month', '₦1,250,000', Colors.green),
          const SizedBox(height: 24),
          const Text('Today\'s Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildBookingCard(context, 'Room 301', 'John Doe', '2 nights'),
          const SizedBox(height: 8),
          _buildBookingCard(context, 'Room 205', 'Jane Smith', '3 nights'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, String room, String guest, String duration) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hotel, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room, style: Theme.of(context).textTheme.labelLarge),
                Text(guest, style: Theme.of(context).textTheme.bodySmall),
                Text(duration,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF10B981)),
        ],
      ),
    );
  }
}

// ============ ADMIN DASHBOARD ============
class AdminDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminDashboard({Key? key, required this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminMetric(context, 'Total Users', '12,453', Colors.blue),
          const SizedBox(height: 12),
          _buildAdminMetric(
              context, 'Total Revenue', '₦2,456,321', Colors.green),
          const SizedBox(height: 12),
          _buildAdminMetric(context, 'Active Transactions', '342', Colors.orange),
          const SizedBox(height: 12),
          _buildAdminMetric(context, 'Disputes', '5', Colors.red),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.supervised_user_circle),
            label: const Text('Manage Users'),
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.gavel),
            label: const Text('Handle Disputes'),
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text('View Analytics'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMetric(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(Icons.dashboard, size: 40, color: color),
        ],
      ),
    );
  }
}

// ============ DEFAULT HOME SCREEN ============
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BusNStay')),
      body: const Center(
        child: Text('Welcome to BusNStay'),
      ),
    );
  }
}
