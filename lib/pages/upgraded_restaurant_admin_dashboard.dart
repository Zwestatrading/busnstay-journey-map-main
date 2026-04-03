import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/menu_management_service.dart';
import '../widgets/professional_ui_widgets.dart';

/// EXAMPLE: Upgraded Restaurant Admin Dashboard with Professional Menus
/// Shows how to integrate the new pro UI into your existing dashboards
class UpgradedRestaurantAdminDashboard extends StatefulWidget {
  final String restaurantId;

  const UpgradedRestaurantAdminDashboard({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<UpgradedRestaurantAdminDashboard> createState() =>
      _UpgradedRestaurantAdminDashboardState();
}

class _UpgradedRestaurantAdminDashboardState
    extends State<UpgradedRestaurantAdminDashboard> {
  int _tabIndex = 0; // 0: Orders, 1: Pro Menu Manager
  late MenuManagementService _menuService;

  @override
  void initState() {
    super.initState();
    _menuService = AppServices.menuService;
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
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ============ TAB SELECTOR ============
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton(0, 'Orders', Icons.receipt),
                _buildTabButton(1, 'Pro Menus', Icons.restaurant_menu),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildOrdersTab()
                : _buildProMenuTab(),
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

  // ============ ORDERS TAB (YOUR EXISTING CODE) ============
  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Orders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // ... your existing order cards ...
          _placeholderOrderCard(),
          _placeholderOrderCard(),
        ],
      ),
    );
  }

  // ============ PRO MENU MANAGER TAB (NEW!) ============
  Widget _buildProMenuTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tabs: View Menu, Add Items
          TabBar(
            labelColor: const Color(0xFFFD5E14),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFD5E14),
            tabs: const [
              Tab(text: '📋 View Menu'),
              Tab(text: '➕ Add Item'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildViewMenuTab(),
                _buildAddItemTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// View all menu items as professional cards
  Widget _buildViewMenuTab() {
    return FutureBuilder<List<MenuCategory>>(
      future: _menuService.getCategories(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];

        return SingleChildScrollView(
          child: Column(
            children: categories.map((category) {
              return FutureBuilder<List<MenuItem>>(
                future: _menuService.getMenuItemsByCategory(
                  restaurantId: widget.restaurantId,
                  category: category.name,
                ),
                builder: (context, itemSnapshot) {
                  final items = itemSnapshot.data ?? [];

                  if (items.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
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
                                ),
                              ),
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

                      // Menu items in this category
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildMenuItemTile(item);
                        },
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Single menu item tile with edit/delete
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
            // Image
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant),
              ),
            const SizedBox(width: 12),

            // Item details
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
                  Row(
                    children: [
                      Text(
                        'K${item.price}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFD5E14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (item.isVegetarian)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🥗 V',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      if (item.isSpicy)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🌶️ S',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
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

  /// Form to add new menu item
  Widget _buildAddItemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '✨ Add Professional Menu Item',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // TODO: Implement form here
          // Use similar code from professional_restaurant_page.dart example
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFD5E14).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to upload image',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Form Implementation:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Image picker\n2. Name input\n3. Price input\n4. Description\n5. Category selector\n6. Vegetarian/Spicy toggles\n7. Submit button',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============

  void _showEditItemModal(MenuItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit: ${item.name}'),
        backgroundColor: const Color(0xFFFD5E14),
      ),
    );
  }

  void _deleteMenuItemConfirm(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _menuService.deleteMenuItem(itemId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Item deleted')),
                );
                setState(() {}); // Refresh
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _placeholderOrderCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #12345',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              Text(
                'Customer: John Doe',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Pending',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ INTEGRATION NOTES ============
/// HOW TO USE THIS:
/// 
/// 1. Replace your old RestaurantAdminDashboard with this one
/// 2. Or add a new tab to your existing dashboard
/// 3. The "Orders" tab keeps your existing functionality
/// 4. The "Pro Menus" tab gives admin professional menu management
///
/// Key Features Added:
/// ✅ View all menu items with images
/// ✅ Categories with images
/// ✅ Vegetarian/Spicy badges
/// ✅ Edit/Delete buttons
/// ✅ Add new items form (ready to implement)
/// ✅ Professional styling with your KFC colors
///
/// Next Step:
/// Implement the _buildAddItemTab() form with:
/// - Image picker
/// - Input fields
/// - Toggle switches
/// - Submit button
