import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/menu_management_service.dart';
import '../services/order_document_service.dart';
import '../services/restaurant_service.dart';
import '../services/transaction_fee_service.dart';
import '../widgets/operations_tracking_board.dart';

class UpgradedRestaurantAdminDashboard extends StatefulWidget {
  final String restaurantId;

  const UpgradedRestaurantAdminDashboard({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  State<UpgradedRestaurantAdminDashboard> createState() =>
      _UpgradedRestaurantAdminDashboardState();
}

class _UpgradedRestaurantAdminDashboardState
    extends State<UpgradedRestaurantAdminDashboard> {
  static const List<String> _fallbackCategories = [
    'Breakfast',
    'Fast Food',
    'Local Meals',
    'Drinks',
    'Desserts',
  ];

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController(
    text: '20',
  );

  int _tabIndex = 0;
  late MenuManagementService _menuService;
  late RestaurantService _restaurantService;
  late OrderDocumentService _orderDocumentService;
  late TransactionFeeService _transactionFeeService;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String _selectedCategory = _fallbackCategories.first;
  bool _isVegetarian = false;
  bool _isSpicy = false;
  bool _isSubmitting = false;
  bool _isGeneratingDocuments = false;
  bool _isStorefrontOpen = true;

  final List<_RestaurantOrderSnapshot> _orderSnapshots = const [
    _RestaurantOrderSnapshot(
      code: 'FO-1482',
      customerName: 'Patricia Banda',
      status: 'Preparing',
      preparationWindow: Duration(minutes: 18),
      destination: 'Intercity pick-up bay',
      basketTotal: 'K128.00',
      items: ['Village chicken combo', 'Mineral water'],
    ),
    _RestaurantOrderSnapshot(
      code: 'FO-1483',
      customerName: 'Daniel Mwila',
      status: 'Dispatching',
      preparationWindow: Duration(minutes: 9),
      destination: 'Bus 3 boarding lane',
      basketTotal: 'K76.50',
      items: ['Burger deluxe', 'Chips'],
    ),
    _RestaurantOrderSnapshot(
      code: 'FO-1484',
      customerName: 'Martha Zulu',
      status: 'Queued',
      preparationWindow: Duration(minutes: 24),
      destination: 'Hotel reception desk',
      basketTotal: 'K210.00',
      items: ['Family nshima platter', 'Fresh juice'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _menuService = AppServices.menuService;
    _restaurantService = AppServices.restaurantService;
    _orderDocumentService = AppServices.orderDocumentService;
    _transactionFeeService = AppServices.transactionFeeService;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Restaurant Manager'),
        backgroundColor: const Color(0xFFFD5E14),
        actions: [
          IconButton(
            icon: _isGeneratingDocuments
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.summarize_outlined),
            tooltip: 'Generate sales report',
            onPressed: _isGeneratingDocuments ? null : _generateDailyReport,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOperationalHeader(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton(0, 'Orders', Icons.receipt_long),
                _buildTabButton(1, 'Pro Menus', Icons.restaurant_menu),
                _buildTabButton(2, 'Control', Icons.tune),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildOrdersTab()
                : _tabIndex == 1
                ? _buildProMenuTab()
                : _buildControlTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFFFD5E14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
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
                      'Restaurant operations hub',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Match the web restaurant dashboard with order flow, menu publishing, and storefront controls in one mobile shell.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isStorefrontOpen ? 'Accepting orders' : 'Paused',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Switch.adaptive(
                    value: _isStorefrontOpen,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green,
                    onChanged: (value) =>
                        setState(() => _isStorefrontOpen = value),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _ControlPill(label: 'Station-linked fulfillment'),
              _ControlPill(label: 'Invoice generation ready'),
              _ControlPill(label: 'Menu image uploads live'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFD5E14) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFFD5E14) : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              height: 2,
              width: 40,
              margin: const EdgeInsets.only(top: 8),
              color: const Color(0xFFFD5E14),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final preparingOrders = _orderSnapshots
        .where((order) => order.status == 'Preparing')
        .length;
    final dispatchingOrders = _orderSnapshots
        .where((order) => order.status == 'Dispatching')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Today Sales',
                value: 'K4,860',
                subtitle: '34 completed baskets',
                icon: Icons.payments_outlined,
                color: Color(0xFFFD5E14),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Prep Accuracy',
                value: '94%',
                subtitle: 'Orders released on time',
                icon: Icons.timer_outlined,
                color: Color(0xFF14B8A6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _isGeneratingDocuments ? null : _generateDailyReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD5E14),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Generate report'),
            ),
            OutlinedButton.icon(
              onPressed: _isGeneratingDocuments
                  ? null
                  : _generateApprovedInvoices,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Generate invoices'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OperationsTrackingBoard(
          title: 'Kitchen and handoff board',
          originLabel: 'Kitchen',
          destinationLabel: 'Pickup',
          accentColor: const Color(0xFFFD5E14),
          entities: const [
            TrackingBoardEntity(
              id: 'kit-1',
              label: 'FO-1482',
              status: 'Preparing',
              color: Color(0xFFF59E0B),
              progress: 0.42,
              detail: 'Village chicken combo for Patricia Banda',
            ),
            TrackingBoardEntity(
              id: 'kit-2',
              label: 'FO-1483',
              status: 'Dispatching',
              color: Color(0xFF14B8A6),
              progress: 0.78,
              detail: 'Burger deluxe heading to Bus 3 lane',
            ),
            TrackingBoardEntity(
              id: 'kit-3',
              label: 'FO-1484',
              status: 'Queued',
              color: Color(0xFF3B82F6),
              progress: 0.16,
              detail: 'Family nshima platter waiting on grill station',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active kitchen orders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$preparingOrders preparing • $dispatchingOrders on handoff',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._orderSnapshots.map(_buildOrderCard),
      ],
    );
  }

  Widget _buildOrderCard(_RestaurantOrderSnapshot order) {
    final color = order.status == 'Preparing'
        ? const Color(0xFFF59E0B)
        : order.status == 'Dispatching'
        ? const Color(0xFF14B8A6)
        : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
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
                      order.code,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      order.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              CountdownBadge(
                label: order.status == 'Dispatching' ? 'ETA' : 'Prep',
                duration: order.preparationWindow,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.destination,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              Text(
                order.basketTotal,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProMenuTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFFFD5E14),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFD5E14),
            tabs: [
              Tab(text: 'View Menu'),
              Tab(text: 'Add Item'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildViewMenuTab(), _buildAddItemTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMenuTab() {
    return FutureBuilder<List<MenuCategory>>(
      future: _menuService.getCategories(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return FutureBuilder<List<MenuItem>>(
            future: _menuService.getMenuItems(widget.restaurantId),
            builder: (context, menuSnapshot) {
              if (menuSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = menuSnapshot.data ?? [];
              if (items.isEmpty) {
                return _buildEmptyMenuState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildMenuItemTile(items[index]),
              );
            },
          );
        }

        return ListView(
          children: categories.map((category) {
            return FutureBuilder<List<MenuItem>>(
              future: _menuService.getMenuItemsByCategory(
                restaurantId: widget.restaurantId,
                category: category.name,
              ),
              builder: (context, itemSnapshot) {
                final items = itemSnapshot.data ?? [];
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        children: [
                          if (category.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                category.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCategoryFallbackIcon(),
                              ),
                            )
                          else
                            _buildCategoryFallbackIcon(),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${items.length} items',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ...items.map(_buildMenuItemTile),
                  ],
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoryFallbackIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFD5E14).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood, color: Color(0xFFFD5E14)),
    );
  }

  Widget _buildEmptyMenuState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 54,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No menu items yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use the Add Item tab to publish your first product with an image, prep time, and dietary tags.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemTile(MenuItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) => _buildItemFallbackIcon(),
                ),
              )
            else
              _buildItemFallbackIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        'K${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFD5E14),
                        ),
                      ),
                      CountdownBadge(
                        label: 'Prep',
                        duration: Duration(
                          minutes: item.preparationTimeMinutes,
                        ),
                        color: const Color(0xFF14B8A6),
                      ),
                      _buildTag(
                        item.isAvailable ? 'Live' : 'Hidden',
                        item.isAvailable
                            ? const Color(0xFF14B8A6)
                            : Colors.grey,
                      ),
                      if (item.isVegetarian) _buildTag('Veg', Colors.green),
                      if (item.isSpicy) _buildTag('Spicy', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch.adaptive(
                  value: item.isAvailable,
                  activeColor: const Color(0xFFFD5E14),
                  onChanged: (_) => _toggleMenuAvailability(item),
                ),
                GestureDetector(
                  onTap: () => _showEditItemModal(item),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFD5E14).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFFFD5E14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _deleteMenuItemConfirm(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Storefront',
                value: _isStorefrontOpen ? 'Open' : 'Paused',
                subtitle: 'Controls inbound orders',
                icon: Icons.storefront_outlined,
                color: _isStorefrontOpen
                    ? const Color(0xFF14B8A6)
                    : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Support lane',
                value: 'Live',
                subtitle: 'Call centre and admin escalation ready',
                icon: Icons.support_agent_outlined,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operational controls',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isStorefrontOpen,
                activeColor: const Color(0xFF14B8A6),
                title: Text(
                  'Accept new orders',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Mirrors the web restaurant open or closed control.',
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
                onChanged: (value) => setState(() => _isStorefrontOpen = value),
              ),
              const Divider(height: 24),
              _controlRow(
                'Invoices',
                'Generate approved order documents for reconciliation',
              ),
              _controlRow(
                'Kitchen handoff',
                'Active order board tracks preparation and dispatching',
              ),
              _controlRow(
                'Menu publishing',
                'Use item toggles to hide unavailable dishes without deleting them',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controlRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMenuAvailability(MenuItem item) async {
    final success = await _menuService.updateMenuItem(
      itemId: item.id,
      isAvailable: !item.isAvailable,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${item.name} is now ${item.isAvailable ? 'hidden' : 'live'}'
              : 'Failed to update ${item.name}',
        ),
      ),
    );

    if (success) {
      setState(() {});
    }
  }

  Widget _buildItemFallbackIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAddItemTab() {
    return FutureBuilder<List<MenuCategory>>(
      future: _menuService.getCategories(widget.restaurantId),
      builder: (context, snapshot) {
        final categories = snapshot.data
            ?.map((category) => category.name)
            .toList();
        final availableCategories = (categories == null || categories.isEmpty)
            ? _fallbackCategories
            : categories;

        if (!availableCategories.contains(_selectedCategory)) {
          _selectedCategory = availableCategories.first;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add Professional Menu Item',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a product image, set preparation timing, and publish it directly to your live menu.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickMenuImage,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFD5E14).withOpacity(0.28),
                    width: 1.4,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFD5E14).withOpacity(0.08),
                      Colors.white,
                    ],
                  ),
                ),
                child: _selectedImageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            size: 42,
                            color: Color(0xFFFD5E14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to upload product image',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFD5E14),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Works for mobile and web pickers',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _selectedImageName ?? 'Picked image',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Item name',
              icon: Icons.fastfood_outlined,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Price (K)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _prepTimeController,
                    label: 'Prep time (min)',
                    icon: Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: availableCategories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: Colors.green,
              title: Text(
                'Vegetarian option',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              value: _isVegetarian,
              onChanged: (value) => setState(() => _isVegetarian = value),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: Colors.red,
              title: Text(
                'Spicy item',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              value: _isSpicy,
              onChanged: (value) => setState(() => _isSpicy = value),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitNewMenuItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD5E14),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _isSubmitting ? 'Publishing item...' : 'Publish menu item',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
    );
  }

  Future<void> _pickMenuImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = image.name;
    });
  }

  Future<void> _submitNewMenuItem() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final prepMinutes = int.tryParse(_prepTimeController.text.trim()) ?? 20;

    if (name.isEmpty || description.isEmpty || price == null) {
      _showMessage('Enter item name, description, and a valid price.', true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final createdItem = await _menuService.createMenuItem(
        restaurantId: widget.restaurantId,
        name: name,
        category: _selectedCategory,
        price: price,
        description: description,
        preparationTimeMinutes: prepMinutes,
        isVegetarian: _isVegetarian,
        isSpicy: _isSpicy,
      );

      if (createdItem == null) {
        _showMessage('Unable to create menu item right now.', true);
        return;
      }

      if (_selectedImageBytes != null) {
        final extension = _resolveExtension(_selectedImageName);
        final imageUrl = await _menuService.uploadMenuItemImageBytes(
          bytes: _selectedImageBytes!,
          restaurantId: widget.restaurantId,
          itemId: createdItem.id,
          extension: extension,
        );

        if (imageUrl != null) {
          await _menuService.updateMenuItem(
            itemId: createdItem.id,
            imageUrl: imageUrl,
          );
        }
      }

      _clearAddItemForm();
      _showMessage('Menu item published successfully.', false);
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _resolveExtension(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return 'jpg';
    }
    return fileName.split('.').last.toLowerCase();
  }

  void _clearAddItemForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _prepTimeController.text = '20';
    _selectedCategory = _fallbackCategories.first;
    _selectedImageBytes = null;
    _selectedImageName = null;
    _isVegetarian = false;
    _isSpicy = false;
  }

  void _showEditItemModal(MenuItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit flow for ${item.name} can be wired next.'),
        backgroundColor: const Color(0xFFFD5E14),
      ),
    );
  }

  void _deleteMenuItemConfirm(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _menuService.deleteMenuItem(itemId);
              if (!mounted) {
                return;
              }
              Navigator.pop(context);
              _showMessage('Item deleted.', false);
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF14B8A6),
      ),
    );
  }

  Future<void> _generateDailyReport() async {
    setState(() => _isGeneratingDocuments = true);
    try {
      final approvedRecords = await _restaurantService.getApprovedOrders(
        widget.restaurantId,
      );
      final approvedOrders = approvedRecords
          .map(_orderDocumentService.foodOrderFromRecord)
          .toList();
      final dailyRevenue = await _transactionFeeService
          .getRestaurantDailyRevenue(
            restaurantId: widget.restaurantId,
            date: DateTime.now(),
          );
      final monthlyRevenue = await _transactionFeeService
          .getRestaurantMonthlyRevenue(
            restaurantId: widget.restaurantId,
            month: DateTime.now().month,
            year: DateTime.now().year,
          );
      final bytes = await _orderDocumentService.generateRestaurantSalesReport(
        restaurantName: approvedOrders.isNotEmpty
            ? approvedOrders.first.restaurantName
            : 'Restaurant ${widget.restaurantId}',
        generatedAt: DateTime.now(),
        orders: approvedOrders,
        dailyRevenue: dailyRevenue,
        monthlyRevenue: monthlyRevenue,
      );

      if (!mounted) {
        return;
      }

      _showDocumentDialog(
        title: 'Sales report generated',
        lines: [
          'Approved orders: ${approvedOrders.length}',
          'Today payout: K${dailyRevenue['restaurant_payout'] ?? '0.00'}',
          'Month payout: K${monthlyRevenue['restaurant_payout'] ?? '0.00'}',
          'PDF size: ${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
        ],
      );
    } catch (e) {
      _showMessage('Failed to generate report: $e', true);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingDocuments = false);
      }
    }
  }

  Future<void> _generateApprovedInvoices() async {
    setState(() => _isGeneratingDocuments = true);
    try {
      final approvedRecords = await _restaurantService.getApprovedOrders(
        widget.restaurantId,
      );
      if (approvedRecords.isEmpty) {
        _showMessage('No approved orders available for invoicing yet.', true);
        return;
      }

      final invoiceLines = <String>[];
      int totalBytes = 0;

      for (final record in approvedRecords.take(5)) {
        final order = _orderDocumentService.foodOrderFromRecord(record);
        final bytes = await _orderDocumentService.generateApprovedOrderInvoice(
          order: order,
        );
        totalBytes += bytes.lengthInBytes;
        invoiceLines.add('${order.orderNumber} -> ${order.invoiceNumber}');
      }

      if (!mounted) {
        return;
      }

      _showDocumentDialog(
        title: 'Approved invoices generated',
        lines: [
          'Generated ${invoiceLines.length} invoice PDFs for approved food orders.',
          ...invoiceLines,
          'Combined PDF output: ${(totalBytes / 1024).toStringAsFixed(1)} KB',
        ],
      );
    } catch (e) {
      _showMessage('Failed to generate invoices: $e', true);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingDocuments = false);
      }
    }
  }

  void _showDocumentDialog({
    required String title,
    required List<String> lines,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line),
                  ),
                )
                .toList(),
          ),
        ),
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

class _RestaurantOrderSnapshot {
  final String code;
  final String customerName;
  final String status;
  final Duration preparationWindow;
  final String destination;
  final String basketTotal;
  final List<String> items;

  const _RestaurantOrderSnapshot({
    required this.code,
    required this.customerName,
    required this.status,
    required this.preparationWindow,
    required this.destination,
    required this.basketTotal,
    required this.items,
  });
}

class _ControlPill extends StatelessWidget {
  final String label;

  const _ControlPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
