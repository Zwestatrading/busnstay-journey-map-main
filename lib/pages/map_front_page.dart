import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';

/// Uber-style map landing page shown before authentication.
/// Displays a full-screen map with route selection, service cards,
/// and a floating "Sign In" button.
class MapFrontPage extends StatefulWidget {
  final VoidCallback onSignInTap;
  final void Function(String service)? onServiceTap;

  const MapFrontPage({
    super.key,
    required this.onSignInTap,
    this.onServiceTap,
  });

  @override
  State<MapFrontPage> createState() => _MapFrontPageState();
}

class _MapFrontPageState extends State<MapFrontPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _routeSelected = false;
  Position? _userPosition;

  // Route selection
  String _pickupText = '';
  String _destinationText = '';
  int _selectedServiceIndex = 0;

  // Default center: Lusaka, Zambia
  static const LatLng _defaultCenter = LatLng(-15.3875, 28.3228);

  // Popular routes
  static const List<_RouteOption> _popularRoutes = [
    _RouteOption('Ndola', 'Lusaka', LatLng(-12.9667, 28.6333), LatLng(-15.4167, 28.2833), '320 km', '~4h 30m'),
    _RouteOption('Lusaka', 'Livingstone', LatLng(-15.4167, 28.2833), LatLng(-17.8419, 25.8544), '470 km', '~6h'),
    _RouteOption('Kitwe', 'Ndola', LatLng(-12.8024, 28.2132), LatLng(-12.9667, 28.6333), '55 km', '~45m'),
    _RouteOption('Kabwe', 'Lusaka', LatLng(-14.4469, 28.4464), LatLng(-15.4167, 28.2833), '130 km', '~1h 40m'),
  ];

  // Service categories
  static const List<_ServiceCategory> _services = [
    _ServiceCategory('Transport', Icons.directions_bus_rounded, AppColors.primary),
    _ServiceCategory('Food', Icons.restaurant_rounded, AppColors.accent),
    _ServiceCategory('Stay', Icons.hotel_rounded, AppColors.teal),
    _ServiceCategory('Delivery', Icons.local_shipping_rounded, AppColors.emerald),
  ];

  // Map markers
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

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
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (mounted) {
        setState(() => _userPosition = pos);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
    } catch (_) {}
  }

  void _selectRoute(_RouteOption route) {
    setState(() {
      _pickupText = route.from;
      _destinationText = route.to;
      _routeSelected = true;

      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('origin'),
          position: route.origin,
          infoWindow: InfoWindow(title: route.from),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ))
        ..add(Marker(
          markerId: const MarkerId('destination'),
          position: route.destination,
          infoWindow: InfoWindow(title: route.to),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));

      _polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId('route'),
          color: AppColors.primary,
          width: 4,
          points: [route.origin, route.destination],
        ));
    });

    // Fit camera to show both markers
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            route.origin.latitude < route.destination.latitude ? route.origin.latitude : route.destination.latitude,
            route.origin.longitude < route.destination.longitude ? route.origin.longitude : route.destination.longitude,
          ),
          northeast: LatLng(
            route.origin.latitude > route.destination.latitude ? route.origin.latitude : route.destination.latitude,
            route.origin.longitude > route.destination.longitude ? route.origin.longitude : route.destination.longitude,
          ),
        ),
        80,
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _pickupText = '';
      _destinationText = '';
      _routeSelected = false;
      _markers.clear();
      _polylines.clear();
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        _userPosition != null
            ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
            : _defaultCenter,
        6,
      ),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userPosition != null
                  ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                  : _defaultCenter,
              zoom: 6,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
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

          // ── Bottom panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _panelAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, (1 - _panelAnimation.value) * 300),
                child: Opacity(opacity: _panelAnimation.value, child: child),
              ),
              child: _buildBottomPanel(context, bottomInset),
            ),
          ),

          // ── Sign In FAB ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _buildSignInButton(context),
          ),

          // ── My-location button ──
          Positioned(
            right: 16,
            bottom: (_routeSelected ? 360 : 280) + bottomInset,
            child: _buildMyLocationButton(),
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

  Widget _buildBottomPanel(BuildContext context, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

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

          if (_routeSelected) ...[
            const SizedBox(height: 18),
            // Continue / Book button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSignInTap,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: Text(
                          'Continue — Sign in to book',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          color: isActive ? AppColors.accent.withOpacity(0.18) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppColors.accent : Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${route.from} → ${route.to}',
              style: TextStyle(
                color: isActive ? AppColors.accentLight : Colors.white,
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

  Widget _buildSignInButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSignInTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: _getUserLocation,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.my_location_rounded, color: AppColors.accentLight, size: 22),
      ),
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
        LatLng(_selectedFrom!.lat, _selectedFrom!.lng),
        LatLng(_selectedTo!.lat, _selectedTo!.lng),
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
  final LatLng origin;
  final LatLng destination;
  final String distance;
  final String duration;

  const _RouteOption(this.from, this.to, this.origin, this.destination, this.distance, this.duration);
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
