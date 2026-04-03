import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/live_location_service.dart';

/// EXAMPLE: Upgraded Bus Operator Dashboard with Live Fleet Tracking
/// Shows how to integrate the LiveLocationService for real-time bus tracking
class UpgradedBusOperatorDashboard extends StatefulWidget {
  final String busOperatorId;

  const UpgradedBusOperatorDashboard({
    Key? key,
    required this.busOperatorId,
  }) : super(key: key);

  @override
  State<UpgradedBusOperatorDashboard> createState() =>
      _UpgradedBusOperatorDashboardState();
}

class _UpgradedBusOperatorDashboardState
    extends State<UpgradedBusOperatorDashboard> {
  int _tabIndex = 0; // 0: Fleet, 1: Live Tracking, 2: Routes
  late LiveLocationService _locationService;
  final List<BusVehicle> _buses = [
    BusVehicle(
      id: 'bus_001',
      registrationNumber: 'ZL-25-ABC-123',
      driverName: 'John Mwale',
      status: 'In Transit',
      destination: 'Lusaka Central',
      latitude: -12.8094,
      longitude: 28.2715,
      passengersOnBoard: 42,
      capacity: 48,
      nextStop: 'Cairo Road Stop',
      eta: '14:30',
    ),
    BusVehicle(
      id: 'bus_002',
      registrationNumber: 'ZL-25-DEF-456',
      driverName: 'Patricia Banda',
      status: 'Idle',
      destination: 'Ndola Station',
      latitude: -13.2005,
      longitude: 28.6352,
      passengersOnBoard: 0,
      capacity: 48,
      nextStop: 'Ready for departure',
      eta: '15:00',
    ),
    BusVehicle(
      id: 'bus_003',
      registrationNumber: 'ZL-25-GHI-789',
      driverName: 'Michael Tembo',
      status: 'Arrived',
      destination: 'Kitwe Hub',
      latitude: -12.8282,
      longitude: 28.2659,
      passengersOnBoard: 48,
      capacity: 48,
      nextStop: 'Awaiting departure clearance',
      eta: '16:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _locationService = AppServices.liveLocationService;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bus Operator Dashboard'),
        backgroundColor: const Color(0xFFFD5E14),
        elevation: 0,
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
                _buildTabButton(0, 'Fleet (3)', Icons.directions_bus),
                _buildTabButton(1, 'Live Map', Icons.map),
                _buildTabButton(2, 'Routes', Icons.route),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildFleetTab()
                : _tabIndex == 1
                    ? _buildLiveMapTab()
                    : _buildRoutesTab(),
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

  // ============ FLEET TAB ============
  Widget _buildFleetTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _buses.length,
      itemBuilder: (context, index) => _buildBusCard(_buses[index]),
    );
  }

  /// Bus card with status, location, and passengers
  Widget _buildBusCard(BusVehicle bus) {
    final statusColor = bus.status == 'In Transit'
        ? Colors.blue
        : bus.status == 'Idle'
            ? Colors.orange
            : Colors.green;

    final occupancyPercent = bus.passengersOnBoard / bus.capacity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.registrationNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      bus.driverName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bus.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body with details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination & ETA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📍 Destination',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            bus.destination,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '⏱️ ETA',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          bus.eta,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFD5E14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Next stop
                Text(
                  '🛑 Next Stop: ${bus.nextStop}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),

                // Passengers occupancy
                Text(
                  '👥 Passengers: ${bus.passengersOnBoard}/${bus.capacity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancyPercent,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      occupancyPercent > 0.8 ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showBusDetailsModal(bus),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFD5E14).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFFFD5E14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFD5E14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _trackBusLive(bus),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFD5E14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Track Live',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ LIVE MAP TAB ============
  Widget _buildLiveMapTab() {
    return Container(
      color: Colors.grey[100],
      child: Stack(
        children: [
          // Google Map placeholder
          Container(
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Google Maps Integration',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shows all 3 buses with live GPS markers\nRed pins: Active routes\nOrange pins: Idle vehicles',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live buses info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Buses (Real-time)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buses.map((bus) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bus.registrationNumber,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${bus.latitude.toStringAsFixed(4)}, ${bus.longitude.toStringAsFixed(4)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFD5E14).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '🔴 Online',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFD5E14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ ROUTES TAB ============
  Widget _buildRoutesTab() {
    final routes = [
      {'name': 'Lusaka ↔ Ndola', 'buses': 2, 'trips': '5/day', 'status': 'Active'},
      {'name': 'Lusaka ↔ Kitwe', 'buses': 1, 'trips': '3/day', 'status': 'Active'},
      {'name': 'Ndola ↔ Kitwe', 'buses': 1, 'trips': '2/day', 'status': 'Paused'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '🚌 ${route['buses']}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '📅 ${route['trips']}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: route['status'] == 'Active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  route['status'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: route['status'] == 'Active'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ HELPER METHODS ============

  void _showBusDetailsModal(BusVehicle bus) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bus Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Registration', bus.registrationNumber),
            _detailRow('Driver', bus.driverName),
            _detailRow('Status', bus.status),
            _detailRow('Destination', bus.destination),
            _detailRow('Passengers', '${bus.passengersOnBoard}/${bus.capacity}'),
            _detailRow('ETA', bus.eta),
          ],
        ),
      ),
    );
  }

  void _trackBusLive(BusVehicle bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking ${bus.registrationNumber}...'),
        backgroundColor: const Color(0xFFFD5E14),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ DATA MODELS ============

class BusVehicle {
  final String id;
  final String registrationNumber;
  final String driverName;
  final String status;
  final String destination;
  final double latitude;
  final double longitude;
  final int passengersOnBoard;
  final int capacity;
  final String nextStop;
  final String eta;

  BusVehicle({
    required this.id,
    required this.registrationNumber,
    required this.driverName,
    required this.status,
    required this.destination,
    required this.latitude,
    required this.longitude,
    required this.passengersOnBoard,
    required this.capacity,
    required this.nextStop,
    required this.eta,
  });
}

// ============ INTEGRATION NOTES ============
/// HOW TO USE THIS:
///
/// 1. Import into your main.dart and use as bus operator screen
/// 2. Connect real data from your Supabase database
/// 3. Implement Google Maps integration in _buildLiveMapTab()
/// 4. Connect LiveLocationService to stream real bus positions
///
/// Key Features Added:
/// ✅ Fleet overview with status badges
/// ✅ Occupancy indicators (progress bars)
/// ✅ Live GPS coordinates
/// ✅ Route management
/// ✅ Driver information
/// ✅ ETA tracking
/// ✅ Track button to view live location
///
/// Integration Steps:
/// 1. Replace placeholder data (_buses list) with real Supabase queries
/// 2. Implement GoogleMapController in _buildLiveMapTab()
/// 3. Add markers for each bus using BitmapDescriptor
/// 4. Stream location updates using LiveLocationService.getLocationStream()
/// 5. Update polylines as buses move
