import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/journey_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../services/app_state.dart';
import '../services/flutterwave_service.dart';
import '../widgets/payment_modal.dart';
import 'order_checkout_page.dart';
import 'order_chat_page.dart';
import '../models/order_chat_model.dart';
import 'professional_restaurant_page.dart';

class PassengerExperiencePage extends StatefulWidget {
  final AppState state;

  const PassengerExperiencePage({super.key, required this.state});

  @override
  State<PassengerExperiencePage> createState() =>
      _PassengerExperiencePageState();
}

class _PassengerExperiencePageState extends State<PassengerExperiencePage> {
  int _tabIndex = 0;

  static const Color _crimson = AppColors.primary;
  static const Color _orange = AppColors.accent;
  static const Color _navy = AppColors.darkBg;
  static const Color _teal = AppColors.teal;

  late final List<JourneyTown> _journeyTowns = [
    JourneyTown(
      townId: 'ndola',
      townName: 'Ndola',
      latitude: -12.9667,
      longitude: 28.6333,
      pickupStationName: 'Main Intercity Station',
      estimatedStopDuration: const Duration(minutes: 20),
      status: TownStatus.locked,
      orderCutoffBeforeETA: const Duration(minutes: 10),
      orderCutoffByDistance: 3,
    ),
    JourneyTown(
      townId: 'kapiri',
      townName: 'Kapiri Mposhi',
      latitude: -13.9715,
      longitude: 28.6699,
      pickupStationName: 'Central Stop',
      estimatedStopDuration: const Duration(minutes: 12),
      status: TownStatus.closed,
      etaToTown: const Duration(minutes: 7),
      distanceToTown: 2.4,
    ),
    JourneyTown(
      townId: 'kabwe',
      townName: 'Kabwe',
      latitude: -14.4469,
      longitude: 28.4464,
      pickupStationName: 'Town Terminal',
      estimatedStopDuration: const Duration(minutes: 18),
      status: TownStatus.open,
      etaToTown: const Duration(minutes: 44),
      distanceToTown: 58.0,
    ),
    JourneyTown(
      townId: 'lusaka',
      townName: 'Lusaka',
      latitude: -15.3875,
      longitude: 28.3228,
      pickupStationName: 'City Terminal',
      estimatedStopDuration: const Duration(minutes: 25),
      status: TownStatus.open,
      etaToTown: const Duration(hours: 2, minutes: 11),
      distanceToTown: 182.0,
    ),
  ];

  final List<_PassengerOrderHistoryItem> _recentOrders = const [
    _PassengerOrderHistoryItem(
      code: 'FD-1042',
      title: 'Copper Pot Express order',
      destination: 'Kabwe pickup bay',
      totalLabel: 'K145.00',
      status: 'Preparing',
      etaLabel: 'Ready in 12 min',
      accent: _orange,
      items: ['Village chicken plate', 'Fresh juice'],
    ),
    _PassengerOrderHistoryItem(
      code: 'HT-2081',
      title: 'Protea Hotel booking',
      destination: 'Lusaka business district',
      totalLabel: 'K420.00',
      status: 'Confirmed',
      etaLabel: 'Check-in after 14:00',
      accent: _teal,
      items: ['Executive room', 'Breakfast included'],
    ),
    _PassengerOrderHistoryItem(
      code: 'FD-0977',
      title: 'Nshima Yard order',
      destination: 'Bus seat 14A delivery',
      totalLabel: 'K88.00',
      status: 'Delivered',
      etaLabel: 'Completed today',
      accent: _crimson,
      items: ['Burger deluxe', 'Chips'],
    ),
  ];

  final List<_PassengerFavoriteItem> _favoriteItems = const [
    _PassengerFavoriteItem(
      title: 'Copper Pot Express',
      subtitle: 'Fast pickup meals at Kabwe station',
      typeLabel: 'Favorite restaurant',
      accent: _orange,
      icon: Icons.restaurant,
    ),
    _PassengerFavoriteItem(
      title: 'Protea Hotel Lusaka',
      subtitle: 'Preferred stay for business arrivals',
      typeLabel: 'Saved hotel',
      accent: _teal,
      icon: Icons.hotel,
    ),
    _PassengerFavoriteItem(
      title: 'Ndola to Lusaka corridor',
      subtitle: 'Pinned route for recurring bookings',
      typeLabel: 'Pinned route',
      accent: Color(0xFF2563EB),
      icon: Icons.route,
    ),
  ];

  final List<_PassengerSavedAddress> _savedAddresses = const [
    _PassengerSavedAddress(
      label: 'Home',
      address: 'Plot 18, Kansenshi, Ndola',
      note: 'Use for evening drop-offs',
      accent: _crimson,
    ),
    _PassengerSavedAddress(
      label: 'Office',
      address: 'Cairo Road business centre, Lusaka',
      note: 'Preferred destination for weekday rides',
      accent: Color(0xFF2563EB),
    ),
    _PassengerSavedAddress(
      label: 'Pickup Point',
      address: 'Intercity terminal, Kabwe bay C',
      note: 'Food and parcel collection point',
      accent: _orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F4EF),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => widget.state.logout(),
            ),
            title: Text(
              _tabIndex == 0
                  ? 'BusNStay Passenger'
                  : _tabIndex == 1
                  ? 'Orders'
                  : _tabIndex == 2
                  ? 'Wallet'
                  : _tabIndex == 3
                  ? 'Saved'
                  : 'Profile',
              style: GoogleFonts.dmSerifDisplay(fontSize: 24),
            ),
            actions: [
              IconButton(
                onPressed: _showRouteStatusSheet,
                icon: const Icon(Icons.route),
                tooltip: 'Journey status',
              ),
              IconButton(
                onPressed: () => widget.state.logout(),
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: IndexedStack(
            index: _tabIndex,
            children: [
              _buildExploreTab(context),
              _buildOrdersTab(context),
              _buildWalletTab(context),
              _buildSavedTab(context),
              _buildProfileTab(context),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => setState(() => _tabIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreTab(BuildContext context) {
    final user = widget.state.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _buildHero(user),
        const SizedBox(height: 20),
        _buildQuickActions(context),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Journey Control',
          'Track route validation, stop availability, and live order windows.',
        ),
        const SizedBox(height: 12),
        _buildJourneyCard(),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Featured Food Stops',
          'Order ahead only from approved partners while the bus is still inbound.',
        ),
        const SizedBox(height: 12),
        ..._restaurantCards(context),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Recommended Stays',
          'Hotel inventory, room categories, and payout-ready booking flow are now surfaced in-app.',
        ),
        const SizedBox(height: 12),
        ..._stayCards(),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Platform Readiness',
          'Offline queue, role dashboards, and payment rails are active in the demo flow.',
        ),
        const SizedBox(height: 12),
        _buildReadinessGrid(),
      ],
    );
  }

  Widget _buildHero(AppUser? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _crimson, _orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33111827),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel, food & stays',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hello ${user?.name ?? 'Traveler'}. Wallet, routes, food ordering, and hotels in one hub.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.travel_explore,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _heroChip(
                'Wallet ${FlutterwaveService.formatZMW(widget.state.wallet.balance)}',
              ),
              _heroChip('${widget.state.loyalty.currentPoints} pts'),
              _heroChip('6 rails live'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(
        'Order food',
        Icons.lunch_dining,
        _orange,
        () => _openRestaurant(context),
      ),
      _QuickActionData(
        'Track route',
        Icons.route,
        _crimson,
        _showRouteStatusSheet,
      ),
      _QuickActionData(
        'Book stay',
        Icons.hotel,
        _teal,
        () => _showHotelBookingPrompt('Protea Hotel Lusaka', 420),
      ),
      _QuickActionData(
        'My orders',
        Icons.receipt_long,
        _navy,
        () => setState(() => _tabIndex = 1),
      ),
      _QuickActionData(
        'Top up wallet',
        Icons.account_balance_wallet,
        const Color(0xFF2563EB),
        () => _showAddFundsModal(context),
      ),
      _QuickActionData(
        'Transfer',
        Icons.send,
        const Color(0xFF7C3AED),
        _showTransferDialog,
      ),
      _QuickActionData(
        'Withdraw',
        Icons.call_received,
        const Color(0xFFEA580C),
        _showWithdrawDialog,
      ),
      _QuickActionData(
        'Checkout demo',
        Icons.shopping_bag,
        const Color(0xFF0F766E),
        () => _openDemoCheckout(context),
      ),
      _QuickActionData(
        'Saved places',
        Icons.favorite,
        const Color(0xFFCA8A04),
        () => setState(() => _tabIndex = 3),
      ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: action.color.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color),
                ),
                const Spacer(),
                Text(
                  action.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Open',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: action.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkBg, Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order history',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${_recentOrders.length} records',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 26,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Recent activity',
          'Review fulfillment progress, re-open preferred providers, or repeat frequent orders.',
        ),
        const SizedBox(height: 12),
        ..._recentOrders.map(_buildOrderHistoryCard),
      ],
    );
  }

  Widget _buildOrderHistoryCard(_PassengerOrderHistoryItem order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: order.accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.code,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: order.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: order.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.destination,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: order.items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _historyMeta('Total', order.totalLabel)),
              Expanded(child: _historyMeta('Status note', order.etaLabel)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderChatPage(
                      orderId: order.code,
                      orderCode: order.code,
                      mySide: ChatSender.passenger,
                      myName: 'Passenger',
                      otherName: order.title.split(' order').first,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_outlined, size: 16),
              label: Text(
                'Chat with store',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _navy,
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyCard() {
    final openTowns = _journeyTowns
        .where((town) => town.status == TownStatus.open)
        .length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ndola to Lusaka',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Route validation enabled. Ordering locks near towns.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$openTowns towns open',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._journeyTowns.map((town) => _buildTownStatusRow(town)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _showRouteStatusSheet,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Review route readiness'),
          ),
        ],
      ),
    );
  }

  Widget _buildTownStatusRow(JourneyTown town) {
    final color = switch (town.status) {
      TownStatus.open => const Color(0xFF059669),
      TownStatus.closed => const Color(0xFFD97706),
      TownStatus.locked => const Color(0xFF6B7280),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  town.townName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  town.availabilityMessage,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            town.pickupStationName,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  List<Widget> _restaurantCards(BuildContext context) {
    final restaurants = [
      _RestaurantPreview(
        name: 'Copper Pot Express',
        id: 'restaurant_approved_001',
        address: 'Intercity terminal, Kabwe',
        location: const LatLng(-14.4469, 28.4464),
        accent: _orange,
        tags: const ['Approved', 'Fast prep', 'Bus pickup'],
      ),
      _RestaurantPreview(
        name: 'Nshima Yard',
        id: 'restaurant_approved_002',
        address: 'Levy Junction, Lusaka',
        location: const LatLng(-15.4167, 28.2833),
        accent: _crimson,
        tags: const ['Verified', 'Family meals', 'Live ordering'],
      ),
    ];

    return restaurants.map((restaurant) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: restaurant.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.restaurant, color: restaurant.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.address,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () =>
                      _openRestaurant(context, restaurant: restaurant),
                  style: FilledButton.styleFrom(
                    backgroundColor: restaurant.accent,
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: restaurant.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: restaurant.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: restaurant.accent,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _stayCards() {
    final stays = [
      _StayPreview('Protea Hotel Lusaka', 'Business stay', 420, _teal),
      _StayPreview(
        'Mukuba Lodge Ndola',
        'Family suite',
        315,
        const Color(0xFF2563EB),
      ),
    ];

    return stays.map((stay) {
      return InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showHotelBookingPrompt(stay.name, stay.startingPrice),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: stay.accent.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stay.name,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 24,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stay.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'From K${stay.startingPrice.toStringAsFixed(0)} per night',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: stay.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.night_shelter_outlined, color: stay.accent, size: 34),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildReadinessGrid() {
    final items = [
      _ReadinessItem(
        'Authentication',
        'Role-aware demo sign-in and session state',
        Icons.verified_user,
        _navy,
      ),
      _ReadinessItem(
        'Offline queue',
        'Local tables for orders, bookings, deliveries, payments',
        Icons.cloud_done,
        _teal,
      ),
      _ReadinessItem(
        'Payments',
        'Mobile money, bank, card, USSD, wallet, fee handling',
        Icons.payments,
        _orange,
      ),
      _ReadinessItem(
        'Dashboards',
        'Passenger, operator, restaurant, hotel, delivery, admin',
        Icons.space_dashboard,
        _crimson,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: item.color.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: item.color),
              const Spacer(),
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletTab(BuildContext context) {
    final wallet = widget.state.wallet;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available balance',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                FlutterwaveService.formatZMW(wallet.balance),
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Platform fee: 10% on checkout flows. Wallet top-ups remain available across supported rails.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _walletAction(
                'Add funds',
                Icons.add_circle_outline,
                const Color(0xFF059669),
                () => _showAddFundsModal(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _walletAction(
                'Transfer',
                Icons.send_outlined,
                const Color(0xFF7C3AED),
                _showTransferDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _walletAction(
                'Withdraw',
                Icons.savings_outlined,
                const Color(0xFFEA580C),
                _showWithdrawDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Loyalty snapshot',
          'Account rewards from the web dashboard are surfaced directly inside the wallet view on mobile.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: _walletSnapshotMetric(
                  'Tier',
                  widget.state.loyalty.tierName,
                  const Color(0xFFCA8A04),
                ),
              ),
              Expanded(
                child: _walletSnapshotMetric(
                  'Points',
                  '${widget.state.loyalty.currentPoints}',
                  _crimson,
                ),
              ),
              Expanded(
                child: _walletSnapshotMetric(
                  'Next tier',
                  '${widget.state.loyalty.pointsToNextTier} pts',
                  _teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Supported Payment Methods',
          'Configured methods visible in the Flutterwave-backed payment flow.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FlutterwaveService.paymentMethods.map((method) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Recent Transactions',
          'Local persistence is active so wallet history survives app reloads.',
        ),
        const SizedBox(height: 12),
        ...wallet.transactions.map(_buildTransactionTile),
      ],
    );
  }

  Widget _walletSnapshotMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _walletAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tx.icon, color: tx.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.method.name,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            FlutterwaveService.formatZMW(tx.amount),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: tx.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_crimson.withValues(alpha: 0.92), _navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorites and saved places',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_favoriteItems.length + _savedAddresses.length} items',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'The mobile app now carries the same saved-destination and favorites intent as the web favorites and addresses pages.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Favorites',
          'Pinned restaurants, stays, and route shortcuts appear here for fast repeat actions.',
        ),
        const SizedBox(height: 12),
        ..._favoriteItems.map(_buildFavoriteTile),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Saved addresses',
          'Delivery and pickup locations mirrored from the web address book.',
        ),
        const SizedBox(height: 12),
        ..._savedAddresses.map(_buildSavedAddressTile),
      ],
    );
  }

  Widget _buildFavoriteTile(_PassengerFavoriteItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.typeLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressTile(_PassengerSavedAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: address.accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: address.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.place_outlined, color: address.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.address,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  address.note,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: address.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final user = widget.state.user;
    final loyalty = widget.state.loyalty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _crimson.withOpacity(0.12),
                child: Text(
                  (user?.name ?? 'T').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28,
                    color: _crimson,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Traveler',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'traveler@busnstay.com',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.phone ?? '+260 97 123 4567',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account summary',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _profileSummaryChip(
                    'Wallet ${FlutterwaveService.formatZMW(widget.state.wallet.balance)}',
                    _navy,
                  ),
                  _profileSummaryChip(
                    '${loyalty.currentPoints} reward points',
                    _crimson,
                  ),
                  _profileSummaryChip(
                    '${_recentOrders.length} recent records',
                    _orange,
                  ),
                  _profileSummaryChip(
                    '${_savedAddresses.length} saved addresses',
                    _teal,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _profileTile(
          Icons.security_outlined,
          'Account security',
          'Password reset and 2FA entry points',
        ),
        _profileTile(
          Icons.sync,
          'Offline sync',
          'Transactions and bookings persist locally before remote sync',
        ),
        _profileTile(
          Icons.support_agent,
          'Support',
          'Journey, hotel, restaurant, and wallet support lanes',
        ),
        _profileTile(
          Icons.history_toggle_off,
          'Order history',
          'Food orders, bookings, and travel actions are available on the Orders tab',
        ),
        _profileTile(
          Icons.favorite_outline,
          'Favorites and addresses',
          'Saved restaurants, hotels, and address book are available on the Saved tab',
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => widget.state.logout(),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _profileSummaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: _navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: _navy),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showAddFundsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentModal(
        title: 'Top up wallet',
        onConfirm: (amount, method) {
          widget.state.addFunds(amount, method);
        },
      ),
    );
  }

  Future<void> _showTransferDialog() async {
    final recipientController = TextEditingController(
      text: 'merchant@busnstay.com',
    );
    final amountController = TextEditingController(text: '120');
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transfer funds'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(labelText: 'Recipient'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (K)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                await widget.state.transferFunds(
                  amount,
                  recipientController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController(text: '200');
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw to mobile money'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (K)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                await widget.state.withdrawFunds(amount);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );
  }

  void _showRouteStatusSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route status and ordering windows',
                style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: _navy),
              ),
              const SizedBox(height: 8),
              Text(
                'Locations already passed are locked. Approaching towns are closed automatically to protect preparation windows.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ..._journeyTowns.map(_buildTownStatusRow),
            ],
          ),
        );
      },
    );
  }

  void _openRestaurant(BuildContext context, {_RestaurantPreview? restaurant}) {
    final target =
        restaurant ??
        _RestaurantPreview(
          name: 'Copper Pot Express',
          id: 'restaurant_approved_001',
          address: 'Intercity terminal, Kabwe',
          location: const LatLng(-14.4469, 28.4464),
          accent: _orange,
          tags: const ['Approved', 'Fast prep', 'Bus pickup'],
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalRestaurantPage(
          restaurantId: target.id,
          restaurantName: target.name,
          restaurantAddress: target.address,
          restaurantLocation: target.location,
        ),
      ),
    );
  }

  void _openDemoCheckout(BuildContext context) {
    final user = widget.state.user;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderCheckoutPage(
          restaurantId: 'restaurant_approved_001',
          restaurantName: 'Copper Pot Express',
          townId: 'kabwe',
          townName: 'Kabwe',
          journeyId: 'journey_ndola_lusaka_demo',
          cartItems: [
            OrderItem(name: 'Village chicken plate', quantity: 1, price: 95),
            OrderItem(name: 'Fresh juice', quantity: 2, price: 25),
          ],
          customerId: user?.id ?? 'passenger_demo',
          customerName: user?.name ?? 'Traveler',
          customerPhone: user?.phone ?? '+260971234567',
          customerEmail: user?.email,
          deliveryFee: 18,
          specialInstructions: 'Please package for bus pickup.',
          pickupAddress: 'Kabwe station collection point',
          deliveryAddress: 'Seat 14A, Lusaka coach',
        ),
      ),
    );
  }

  Future<void> _showHotelBookingPrompt(String hotelName, double price) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hotelName),
          content: Text(
            'Room inventory is active in the hotel dashboard. Passenger booking flow is staged here at K${price.toStringAsFixed(0)} per night.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddFundsModal(context);
              },
              child: const Text('Fund wallet'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData(this.title, this.icon, this.color, this.onTap);
}

class _RestaurantPreview {
  final String name;
  final String id;
  final String address;
  final LatLng location;
  final Color accent;
  final List<String> tags;

  const _RestaurantPreview({
    required this.name,
    required this.id,
    required this.address,
    required this.location,
    required this.accent,
    required this.tags,
  });
}

class _StayPreview {
  final String name;
  final String subtitle;
  final double startingPrice;
  final Color accent;

  const _StayPreview(this.name, this.subtitle, this.startingPrice, this.accent);
}

class _ReadinessItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ReadinessItem(this.title, this.description, this.icon, this.color);
}

class _PassengerOrderHistoryItem {
  final String code;
  final String title;
  final String destination;
  final String totalLabel;
  final String status;
  final String etaLabel;
  final Color accent;
  final List<String> items;

  const _PassengerOrderHistoryItem({
    required this.code,
    required this.title,
    required this.destination,
    required this.totalLabel,
    required this.status,
    required this.etaLabel,
    required this.accent,
    required this.items,
  });
}

class _PassengerFavoriteItem {
  final String title;
  final String subtitle;
  final String typeLabel;
  final Color accent;
  final IconData icon;

  const _PassengerFavoriteItem({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.accent,
    required this.icon,
  });
}

class _PassengerSavedAddress {
  final String label;
  final String address;
  final String note;
  final Color accent;

  const _PassengerSavedAddress({
    required this.label,
    required this.address,
    required this.note,
    required this.accent,
  });
}




