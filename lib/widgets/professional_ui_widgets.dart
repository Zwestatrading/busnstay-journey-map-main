import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/menu_management_service.dart';

// ============ PROFESSIONAL MENU CARD ============
class ProfessionalMenuCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback? onAddCart;

  const ProfessionalMenuCard({
    Key? key,
    required this.item,
    required this.onTap,
    this.onAddCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // ============ IMAGE SECTION ============
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 60,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 60,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                ),
                // ============ BADGES ============
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isVegetarian)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🥗 Veg',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (item.isSpicy)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🌶️ Hot',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ============ RATING ============
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ============ CONTENT SECTION ============
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                        height: 1.3,
                      ),
                    ),

                    const Spacer(),

                    // Footer: Price + Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'K${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '⏱️ ${item.preparationTimeMinutes}min',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (item.isAvailable)
                          GestureDetector(
                            onTap: onAddCart,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFD5E14),
                                    Color(0xFFF97316),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unavailable',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PROFESSIONAL MENU GRID ============
class ProfessionalMenuGrid extends StatelessWidget {
  final List<MenuItem> items;
  final Function(MenuItem) onItemTap;
  final Function(MenuItem) onAddCart;

  const ProfessionalMenuGrid({
    Key? key,
    required this.items,
    required this.onItemTap,
    required this.onAddCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ProfessionalMenuCard(
          item: items[index],
          onTap: () => onItemTap(items[index]),
          onAddCart: () => onAddCart(items[index]),
        );
      },
    );
  }
}

// ============ LIVE TRACKING MAP ============
class LiveTrackingMap extends StatefulWidget {
  final LatLng initialLocation;
  final String title;
  final String? destinationName;
  final LatLng? destination;
  final Function(LatLng)? onLocationChanged;

  const LiveTrackingMap({
    Key? key,
    required this.initialLocation,
    required this.title,
    this.destinationName,
    this.destination,
    this.onLocationChanged,
  }) : super(key: key);

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _setupMarkers() {
    // Current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: widget.initialLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    // Destination marker if provided
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          infoWindow: InfoWindow(title: widget.destinationName ?? 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      // Draw polyline between current and destination
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [widget.initialLocation, widget.destination!],
          color: const Color(0xFF3B82F6),
          width: 4,
          geodesic: true,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _animateToLocation(widget.initialLocation);
  }

  void _animateToLocation(LatLng location) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(location, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation,
            zoom: 15,
          ),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
        // Top card with info
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (widget.destinationName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFFFD5E14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.destinationName!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}

// ============ CATEGORY SIDEBAR ============
class MenuCategorySidebar extends StatelessWidget {
  final List<MenuCategory> categories;
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const MenuCategorySidebar({
    Key? key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Colors.grey.withOpacity(0.05),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category.id;

          return GestureDetector(
            onTap: () => onCategorySelected(category.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFD5E14).withOpacity(0.1)
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFD5E14)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (category.imageUrl != null)
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(category.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFD5E14).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFFFD5E14),
                      ),
                    ),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFFD5E14)
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ MENU FILTER CHIP ============
class MenuFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;

  const MenuFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFD5E14) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFD5E14)
                : const Color(0xFFFD5E14).withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? Colors.white : const Color(0xFFFD5E14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
