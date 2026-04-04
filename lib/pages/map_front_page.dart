import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import 'forgot_password_page.dart';

/// Uber-style map landing page with inline role selection and sign-in.
/// Everything lives on one screen — no separate auth page.
class MapFrontPage extends StatefulWidget {
  final void Function(String service)? onServiceTap;

  const MapFrontPage({
    super.key,
    this.onServiceTap,
  });

  @override
  State<MapFrontPage> createState() => _MapFrontPageState();
}

class _MapFrontPageState extends State<MapFrontPage>
    with SingleTickerProviderStateMixin {
  bool _routeSelected = false;

  // Route selection
  String _pickupText = '';
  String _destinationText = '';
  int _selectedServiceIndex = 0;

  // Auth state
  bool _isLogin = true;
  bool _showForgotPassword = false;
  UserRole _selectedRole = UserRole.passenger;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Default center: Lusaka, Zambia (kept for route options data)
  static const List<_RouteOption> _popularRoutes = [
    _RouteOption('Ndola', 'Lusaka', '320 km', '~4h 30m'),
    _RouteOption('Lusaka', 'Livingstone', '470 km', '~6h'),
    _RouteOption('Kitwe', 'Ndola', '55 km', '~45m'),
    _RouteOption('Kabwe', 'Lusaka', '130 km', '~1h 40m'),
  ];

  // Service categories
  static const List<_ServiceCategory> _services = [
    _ServiceCategory('Transport', Icons.directions_bus_rounded, AppColors.primary),
    _ServiceCategory('Food', Icons.restaurant_rounded, AppColors.accent),
    _ServiceCategory('Stay', Icons.hotel_rounded, AppColors.teal),
    _ServiceCategory('Delivery', Icons.local_shipping_rounded, AppColors.emerald),
  ];

  late AnimationController _panelController;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelAnimation = CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);
    _panelController.forward();
  }

  void _selectRoute(_RouteOption route) {
    setState(() {
      _pickupText = route.from;
      _destinationText = route.to;
      _routeSelected = true;
    });
  }

  void _clearRoute() {
    setState(() {
      _pickupText = '';
      _destinationText = '';
      _routeSelected = false;
    });
  }

  @override
  void dispose() {
    _panelController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showForgotPassword) {
      return ForgotPasswordScreen(
        onBackToLogin: () => setState(() => _showForgotPassword = false),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map (or placeholder when no API key) ──
          _MapBackground(
            routeSelected: _routeSelected,
            pickup: _pickupText,
            destination: _destinationText,
          ),

          // ── Gradient overlay at bottom ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.32,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(gradient: AppColors.mapOverlayGradient),
              ),
            ),
          ),

          // ── Top bar: Search / Where to? ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildSearchBar(context),
          ),

          // ── Scrollable bottom panel (routes + role grid + sign in) ──
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.18,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.18, 0.42, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
                  children: [
                    const SizedBox(height: 10),
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Service categories
                    SizedBox(
                      height: 72,
                      child: Row(
                        children: List.generate(_services.length, (i) {
                          final s = _services[i];
                          final isSelected = _selectedServiceIndex == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedServiceIndex = i);
                                widget.onServiceTap?.call(s.label);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? s.color.withOpacity(0.15) : AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? s.color : Colors.white10,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(s.icon, color: isSelected ? s.color : Colors.white54, size: 24),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.label,
                                      style: TextStyle(
                                        color: isSelected ? s.color : Colors.white54,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Popular routes
                    Text(
                      'Popular routes',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularRoutes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => _buildRouteChip(_popularRoutes[i]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Role selection grid ──
                    Text(
                      'Choose your role',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.05,
                      children: [
                        _buildRoleCard('Passenger', 'Icons/Passenger.jpg', UserRole.passenger),
                        _buildRoleCard('Transport', 'Icons/Bus operator Icon.jpg', UserRole.busOperator),
                        _buildRoleCard('Restaurant', 'Icons/Restaurant_icon.jpg', UserRole.restaurantAdmin),
                        _buildRoleCard('Delivery', 'Icons/Delivery_icon.jpg', UserRole.deliveryAgent),
                        _buildRoleCard('Hotel', 'Icons/Hotel_icon.jpg', UserRole.hotelManager),
                        _buildRoleCard('Admin', 'Icons/Admin icon.jpg', UserRole.platformAdmin),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Selected role summary ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected role experience', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(_roleLabel(_selectedRole), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(_roleSummary(_selectedRole), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Sign in form ──
                    _buildSignInForm(context, bottomInset),
                  ],
                ),
              );
            },
          ),

          // ── My-location button ──
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: GestureDetector(
              onTap: () {}, // GPS available once Google Maps API key is set
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.my_location_rounded, color: AppColors.accentLight, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    if (_routeSelected) {
      return _buildRouteHeader(context);
    }

    return GestureDetector(
      onTap: () => _showRouteSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Where are you going?',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentLight)),
                  Container(width: 2, height: 24, color: Colors.white24),
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(2), color: AppColors.primary)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_pickupText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    const Divider(color: Colors.white12, height: 20),
                    Text(_destinationText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                onPressed: _clearRoute,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteChip(_RouteOption route) {
    final isActive = _pickupText == route.from && _destinationText == route.to;
    return GestureDetector(
      onTap: () => _selectRoute(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.18) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppColors.primary : Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${route.from} → ${route.to}',
              style: TextStyle(
                color: isActive ? AppColors.primaryLight : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${route.distance}  •  ${route.duration}',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Role helpers ──

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.passenger: return 'Passenger';
      case UserRole.busOperator: return 'Bus or Taxi Operator';
      case UserRole.restaurantAdmin: return 'Restaurant';
      case UserRole.deliveryAgent: return 'Delivery';
      case UserRole.hotelManager: return 'Hotel';
      case UserRole.platformAdmin: return 'Admin';
      default: return 'User';
    }
  }

  String _roleSummary(UserRole role) {
    switch (role) {
      case UserRole.passenger: return 'Access journeys, orders, saved places, wallet activity, and profile tools.';
      case UserRole.busOperator: return 'Monitor bus or taxi movement, route windows, dispatch readiness, and occupancy.';
      case UserRole.restaurantAdmin: return 'Control storefront availability, orders, menu publishing, and restaurant reporting.';
      case UserRole.deliveryAgent: return 'Manage delivery runs, online status, wallet payouts, and recent transactions.';
      case UserRole.hotelManager: return 'Track bookings, room service, room inventory, and hotel performance.';
      case UserRole.platformAdmin: return 'Review approvals, watch fleet operations, and monitor system health.';
      default: return 'Choose a role to continue.';
    }
  }

  String _defaultEmailFor(UserRole role) {
    switch (role) {
      case UserRole.passenger: return 'traveler@busnstay.demo';
      case UserRole.busOperator: return 'operator@busnstay.demo';
      case UserRole.restaurantAdmin: return 'restaurant@busnstay.demo';
      case UserRole.deliveryAgent: return 'rider@busnstay.demo';
      case UserRole.hotelManager: return 'hotel@busnstay.demo';
      case UserRole.platformAdmin: return 'admin@busnstay.demo';
      default: return AppState.demoEmail;
    }
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password.')),
      );
      return;
    }

    final appState = context.read<AppState>();
    final success = _isLogin
        ? await appState.signIn(email: email, password: password, role: _selectedRole)
        : await appState.signUp(email: email, password: password, name: _roleLabel(_selectedRole), role: _selectedRole);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.authError ?? 'Authentication failed.')),
      );
    }
  }

  Widget _buildRoleCard(String label, String imagePath, UserRole role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
        if (kDebugMode) {
          _emailController.text = _defaultEmailFor(role);
          _passwordController.text = AppState.demoPassword;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.darkCard,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelected
                      ? [AppColors.primary.withOpacity(0.16), AppColors.darkBg.withOpacity(0.12), AppColors.primary.withOpacity(0.35)]
                      : [Colors.black.withOpacity(0.04), Colors.black.withOpacity(0.18), Colors.black.withOpacity(0.50)],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Selected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.36),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context, double bottomInset) {
    final appState = context.watch<AppState>();
    final isBusy = appState.isAuthenticating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Demo credentials (debug only)
        if (kDebugMode) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Demo credentials', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Email: ${AppState.demoEmail}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Password: ${AppState.demoPassword}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _emailController.text = AppState.demoEmail;
                    _passwordController.text = AppState.demoPassword;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Use demo credentials', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Email
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _emailController,
            enabled: !isBusy,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.email, color: AppColors.primary.withOpacity(0.6), size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Password
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _passwordController,
            enabled: !isBusy,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.lock, color: AppColors.primary.withOpacity(0.6), size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Forgot password
        if (_isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _showForgotPassword = true),
              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        const SizedBox(height: 14),

        // Sign in button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : _submitAuth,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: isBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(
                          _isLogin ? 'Login' : 'Register',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.4),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Toggle login/register
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? "Don't have an account? " : 'Already have an account? ',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Register' : 'Login',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showRouteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RouteSelectionSheet(
        onRouteSelected: (route) {
          Navigator.pop(context);
          _selectRoute(route);
        },
      ),
    );
  }
}

// ── Route Selection Bottom Sheet ──
class _RouteSelectionSheet extends StatefulWidget {
  final void Function(_RouteOption route) onRouteSelected;

  const _RouteSelectionSheet({required this.onRouteSelected});

  @override
  State<_RouteSelectionSheet> createState() => _RouteSelectionSheetState();
}

class _RouteSelectionSheetState extends State<_RouteSelectionSheet> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  static const List<_TownSuggestion> _towns = [
    _TownSuggestion('Lusaka', -15.4167, 28.2833),
    _TownSuggestion('Ndola', -12.9667, 28.6333),
    _TownSuggestion('Kitwe', -12.8024, 28.2132),
    _TownSuggestion('Kabwe', -14.4469, 28.4464),
    _TownSuggestion('Livingstone', -17.8419, 25.8544),
    _TownSuggestion('Chipata', -13.6333, 32.6500),
    _TownSuggestion('Solwezi', -12.1667, 25.8500),
    _TownSuggestion('Kasama', -10.2167, 31.1833),
  ];

  List<_TownSuggestion> _filteredFrom = [];
  List<_TownSuggestion> _filteredTo = [];
  _TownSuggestion? _selectedFrom;
  _TownSuggestion? _selectedTo;

  void _filterFrom(String query) {
    setState(() {
      _filteredFrom = query.isEmpty
          ? []
          : _towns.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _filterTo(String query) {
    setState(() {
      _filteredTo = query.isEmpty
          ? []
          : _towns.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _tryConfirm() {
    if (_selectedFrom != null && _selectedTo != null) {
      final dist = Geolocator.distanceBetween(
        _selectedFrom!.lat, _selectedFrom!.lng,
        _selectedTo!.lat, _selectedTo!.lng,
      );
      final km = (dist / 1000).round();
      final hours = (km / 80).toStringAsFixed(0);

      widget.onRouteSelected(_RouteOption(
        _selectedFrom!.name,
        _selectedTo!.name,
        '$km km',
        '~${hours}h',
      ));
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          const Text('Plan your route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 18),

          // From field
          _buildLocationField(
            controller: _fromController,
            hint: 'Pickup location',
            icon: Icons.radio_button_checked,
            iconColor: AppColors.accentLight,
            onChanged: _filterFrom,
          ),

          // Connector line
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 18, color: Colors.white12),
            ),
          ),

          // To field
          _buildLocationField(
            controller: _toController,
            hint: 'Destination',
            icon: Icons.location_on,
            iconColor: AppColors.primary,
            onChanged: _filterTo,
          ),

          // Suggestions
          if (_filteredFrom.isNotEmpty && _selectedFrom == null)
            _buildSuggestionList(_filteredFrom, (town) {
              setState(() {
                _selectedFrom = town;
                _fromController.text = town.name;
                _filteredFrom = [];
              });
              _tryConfirm();
            }),
          if (_filteredTo.isNotEmpty && _selectedTo == null)
            _buildSuggestionList(_filteredTo, (town) {
              setState(() {
                _selectedTo = town;
                _toController.text = town.name;
                _filteredTo = [];
              });
              _tryConfirm();
            }),

          const SizedBox(height: 14),

          // Quick suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _towns.take(6).map((town) {
              return GestureDetector(
                onTap: () {
                  if (_selectedFrom == null) {
                    setState(() {
                      _selectedFrom = town;
                      _fromController.text = town.name;
                    });
                  } else if (_selectedTo == null) {
                    setState(() {
                      _selectedTo = town;
                      _toController.text = town.name;
                    });
                    _tryConfirm();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(town.name, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(List<_TownSuggestion> towns, ValueChanged<_TownSuggestion> onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: towns.length,
        itemBuilder: (context, i) {
          final town = towns[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_city, color: AppColors.primary, size: 18),
            title: Text(town.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () => onTap(town),
          );
        },
      ),
    );
  }
}

// ── Data models ──
class _RouteOption {
  final String from;
  final String to;
  final String distance;
  final String duration;

  const _RouteOption(this.from, this.to, this.distance, this.duration);
}

class _ServiceCategory {
  final String label;
  final IconData icon;
  final Color color;

  const _ServiceCategory(this.label, this.icon, this.color);
}

class _TownSuggestion {
  final String name;
  final double lat;
  final double lng;

  const _TownSuggestion(this.name, this.lat, this.lng);
}

// ── Map Background Placeholder ──
// Shows a rich dark map-like background until Google Maps API key is configured.
class _MapBackground extends StatelessWidget {
  final bool routeSelected;
  final String pickup;
  final String destination;

  const _MapBackground({
    required this.routeSelected,
    required this.pickup,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A2535),
      child: Stack(
        children: [
          // Grid overlay to simulate map tiles
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),
          // Road-like lines
          CustomPaint(
            size: Size.infinite,
            painter: _MapRoadsPainter(routeSelected: routeSelected),
          ),
          // Zambia label
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ZAMBIA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.08),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                ),
              ),
            ),
          ),
          // City dots
          ..._buildCityDots(context),
          // Route label if selected
          if (routeSelected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12),
                    ],
                  ),
                  child: Text(
                    '$pickup → $destination',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCityDots(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Approximate positions on screen for major Zambian cities
    final cities = [
      _CityDot('Lusaka', size.width * 0.52, size.height * 0.54, true),
      _CityDot('Ndola', size.width * 0.55, size.height * 0.28, false),
      _CityDot('Kitwe', size.width * 0.49, size.height * 0.25, false),
      _CityDot('Livingstone', size.width * 0.50, size.height * 0.74, false),
      _CityDot('Kabwe', size.width * 0.52, size.height * 0.45, false),
    ];
    return cities.map((c) => Positioned(
      left: c.x - 4,
      top: c.y - 4,
      child: Column(
        children: [
          Container(
            width: c.isCapital ? 10 : 7,
            height: c.isCapital ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.isCapital ? AppColors.primary : Colors.white.withOpacity(0.55),
              boxShadow: c.isCapital
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                  : [],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            c.name,
            style: TextStyle(
              color: c.isCapital ? AppColors.primaryLight : Colors.white.withOpacity(0.5),
              fontSize: c.isCapital ? 10 : 9,
              fontWeight: c.isCapital ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    )).toList();
  }
}

class _CityDot {
  final String name;
  final double x;
  final double y;
  final bool isCapital;
  const _CityDot(this.name, this.x, this.y, this.isCapital);
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF243045)
      ..strokeWidth = 0.8;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapRoadsPainter extends CustomPainter {
  final bool routeSelected;
  const _MapRoadsPainter({required this.routeSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF2E3F55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = AppColors.primary.withOpacity(routeSelected ? 0.7 : 0.0)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Main north-south highway (Great North Road)
    final path1 = Path()
      ..moveTo(size.width * 0.50, size.height * 0.12)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.40, size.width * 0.52, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.51, size.height * 0.65, size.width * 0.50, size.height * 0.82);
    canvas.drawPath(path1, roadPaint);
    if (routeSelected) canvas.drawPath(path1, highlightPaint);

    // East-west road
    final path2 = Path()
      ..moveTo(size.width * 0.15, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.52, size.width * 0.52, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.53, size.width * 0.85, size.height * 0.48);
    canvas.drawPath(path2, roadPaint);

    // Copperbelt road
    final path3 = Path()
      ..moveTo(size.width * 0.43, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.34, size.width * 0.50, size.height * 0.42);
    canvas.drawPath(path3, roadPaint..color = const Color(0xFF2E3F55));
  }

  @override
  bool shouldRepaint(covariant _MapRoadsPainter old) => old.routeSelected != routeSelected;
}
