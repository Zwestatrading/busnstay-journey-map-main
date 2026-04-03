import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../main.dart';
import '../services/menu_management_service.dart';
import '../theme/app_colors.dart';
import '../widgets/professional_ui_widgets.dart';

/// Example: Professional Restaurant Page with Live Tracking & Pro Menus
class ProfessionalRestaurantPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final LatLng restaurantLocation;

  const ProfessionalRestaurantPage({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLocation,
  }) : super(key: key);

  @override
  State<ProfessionalRestaurantPage> createState() =>
      _ProfessionalRestaurantPageState();
}

class _ProfessionalRestaurantPageState
    extends State<ProfessionalRestaurantPage> {
  late MenuManagementService _menuService;
  List<MenuCategory> _categories = [];
  List<MenuItem> _allMenuItems = [];
  List<MenuItem> _filteredItems = [];
  String? _selectedCategory;
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: Menu, 1: Live Tracking, 2: Info

  // Filter states
  bool _showVegetarianOnly = false;
  bool _showSpicyOnly = false;

  @override
  void initState() {
    super.initState();
    _menuService = AppServices.menuService;
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    try {
      setState(() => _isLoading = true);

      // Load categories
      _categories = await _menuService.getCategories(widget.restaurantId);
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first.id;
      }

      // Load all menu items
      _allMenuItems = await _menuService.getMenuItems(widget.restaurantId);
      _applyFilters();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading menu: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredItems = _allMenuItems.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_showVegetarianOnly && !item.isVegetarian) {
        return false;
      }
      if (_showSpicyOnly && !item.isSpicy) {
        return false;
      }
      return true;
    }).toList();

    setState(() {});
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _applyFilters();
    });
  }

  void _onAddToCart(MenuItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.name} to cart! K${item.price}'),
        backgroundColor: const Color(0xFFFD5E14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.05),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ============ HERO IMAGE SLIVER ============
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.grey.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 100,
                          color: Color(0xFFFD5E14),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    // Restaurant info
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurantName,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 18, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                '4.8 (342 reviews)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🟢 Open',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFFFD5E14),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFFD5E14),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ============ TAB SELECTOR ============
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabButton(0, 'Menu', Icons.restaurant_menu),
                        _buildTabButton(1, 'Tracking', Icons.location_on),
                        _buildTabButton(2, 'Info', Icons.info_outline),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedTabIndex == 0
                        ? _buildMenuTab()
                        : _selectedTabIndex == 1
                            ? _buildTrackingTab()
                            : _buildInfoTab(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isSelected ? const Color(0xFFFD5E14) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFFD5E14)
                  : Colors.grey,
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

  Widget _buildMenuTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ============ FILTER CHIPS ============
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    MenuFilterChip(
                      label: 'Vegetarian',
                      emoji: '🥗',
                      isSelected: _showVegetarianOnly,
                      onTap: () {
                        setState(() {
                          _showVegetarianOnly = !_showVegetarianOnly;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    MenuFilterChip(
                      label: 'Spicy',
                      emoji: '🌶️',
                      isSelected: _showSpicyOnly,
                      onTap: () {
                        setState(() {
                          _showSpicyOnly = !_showSpicyOnly;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============ MENU ITEMS ============
          if (_filteredItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No items match your filters',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ProfessionalMenuGrid(
              items: _filteredItems,
              onItemTap: (item) {
                _showItemDetailsModal(item);
              },
              onAddCart: _onAddToCart,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    return LiveTrackingMap(
      initialLocation: widget.restaurantLocation,
      title: widget.restaurantName,
      destinationName: 'Your Location',
      destination:
          const LatLng(-17.8252, 25.8752), // Example user location
      onLocationChanged: (location) {
        print('📍 Location changed: $location');
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address
          _buildInfoSection(
            icon: Icons.location_on,
            title: 'Address',
            content: widget.restaurantAddress,
          ),
          const SizedBox(height: 20),

          // Hours
          _buildInfoSection(
            icon: Icons.access_time,
            title: 'Hours',
            content: 'Mon-Sun: 10:00 AM - 11:00 PM',
          ),
          const SizedBox(height: 20),

          // Phone
          _buildInfoSection(
            icon: Icons.phone,
            title: 'Phone',
            content: '+260-96-123-4567',
            isClickable: true,
          ),
          const SizedBox(height: 20),

          // Description
          _buildInfoSection(
            icon: Icons.description,
            title: 'About',
            content:
                'Award-winning restaurant serving authentic cuisine with the freshest ingredients. Our chefs prepare each dish with passion and precision.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool isClickable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFD5E14), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsModal(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 18, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '⏱️ ${item.preparationTimeMinutes}min',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'K${item.price.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Add to Cart',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
