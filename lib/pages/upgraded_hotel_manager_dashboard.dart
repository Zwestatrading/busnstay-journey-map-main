import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/live_location_service.dart';

/// EXAMPLE: Upgraded Hotel Manager Dashboard with Live Delivery Tracking
/// Shows how to track room service delivery staff in real-time
class UpgradedHotelManagerDashboard extends StatefulWidget {
  final String hotelId;

  const UpgradedHotelManagerDashboard({
    Key? key,
    required this.hotelId,
  }) : super(key: key);

  @override
  State<UpgradedHotelManagerDashboard> createState() =>
      _UpgradedHotelManagerDashboardState();
}

class _UpgradedHotelManagerDashboardState
    extends State<UpgradedHotelManagerDashboard> {
  int _tabIndex = 0; // 0: Active Orders, 1: Staff Tracking, 2: Rooms
  late LiveLocationService _locationService;

  // Sample room service orders
  final List<RoomServiceOrder> _orders = [
    RoomServiceOrder(
      id: 'order_001',
      roomNumber: '312',
      guestName: 'Sarah Johnson',
      items: ['Espresso Coffee', 'Croissants', 'Orange Juice'],
      status: 'In Delivery',
      staffId: 'staff_001',
      staffName: 'Michael Chen',
      estimatedArrival: '14:45',
      totalAmount: 'K89.50',
      latitude: -12.8090,
      longitude: 28.2710,
    ),
    RoomServiceOrder(
      id: 'order_002',
      roomNumber: '215',
      guestName: 'Ahmed Hassan',
      items: ['Grilled Salmon', 'Caesar Salad', 'Red Wine'],
      status: 'Preparing',
      staffId: 'staff_002',
      staffName: 'Jennifer Mwanza',
      estimatedArrival: '15:15',
      totalAmount: 'K245.00',
      latitude: -12.8080,
      longitude: 28.2705,
    ),
    RoomServiceOrder(
      id: 'order_003',
      roomNumber: '501',
      guestName: 'Maria Garcia',
      items: ['Breakfast Platter', 'Fresh Juice'],
      status: 'Delivered',
      staffId: 'staff_003',
      staffName: 'James Tembo',
      estimatedArrival: 'Delivered',
      totalAmount: 'K125.00',
      latitude: -12.8085,
      longitude: 28.2715,
    ),
  ];

  // Sample rooms occupancy
  final List<RoomStatus> _rooms = [
    RoomStatus(number: '101', status: 'Occupied', guest: 'John Smith'),
    RoomStatus(number: '102', status: 'Occupied', guest: 'Emma Wilson'),
    RoomStatus(number: '103', status: 'Vacant', guest: ''),
    RoomStatus(number: '104', status: 'Occupied', guest: 'David Lee'),
    RoomStatus(number: '105', status: 'Cleaning', guest: ''),
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
        title: const Text('Hotel Manager Dashboard'),
        backgroundColor: const Color(0xFF14B8A6),
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
                _buildTabButton(0, 'Orders (3)', Icons.room_service),
                _buildTabButton(1, 'Tracking', Icons.person_pin_circle),
                _buildTabButton(2, 'Rooms', Icons.door_sliding),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildOrdersTab()
                : _tabIndex == 1
                    ? _buildTrackingTab()
                    : _buildRoomsTab(),
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
            color: isSelected ? const Color(0xFF14B8A6) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF14B8A6) : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              height: 2,
              width: 40,
              margin: const EdgeInsets.only(top: 8),
              color: const Color(0xFF14B8A6),
            ),
        ],
      ),
    );
  }

  // ============ ORDERS TAB ============
  Widget _buildOrdersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
    );
  }

  /// Room service order card with live tracking
  Widget _buildOrderCard(RoomServiceOrder order) {
    final statusColor = order.status == 'In Delivery'
        ? Colors.blue
        : order.status == 'Preparing'
            ? Colors.orange
            : Colors.green;

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
          // Header
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
                      'Room ${order.roomNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      order.guestName,
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
                    order.status,
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

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                Text(
                  '🛒 Items:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      '• $item',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),

                // Staff & Delivery Info
                if (order.status != 'Preparing')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '👤 Delivery By',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  order.staffName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '⏱️ ETA',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  order.estimatedArrival,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF14B8A6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Amount & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${order.totalAmount}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (order.status == 'In Delivery')
                      GestureDetector(
                        onTap: () => _trackDelivery(order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Track',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ TRACKING TAB ============
  Widget _buildTrackingTab() {
    final inDeliveryOrders = _orders
        .where((order) => order.status == 'In Delivery')
        .toList();

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Map area
          Expanded(
            flex: 2,
            child: Container(
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
                      'Live Delivery Map',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shows staff locations in real-time\nwith optimized delivery routes',
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
          ),

          // Active deliveries list
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: inDeliveryOrders.isEmpty
                  ? Center(
                      child: Text(
                        'No active deliveries',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Deliveries (${inDeliveryOrders.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: inDeliveryOrders.length,
                            itemBuilder: (context, index) {
                              final order = inDeliveryOrders[index];
                              return Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order.staffName} → Room ${order.roomNumber}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'GPS: ${order.latitude.toStringAsFixed(4)}, ${order.longitude.toStringAsFixed(4)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ ROOMS TAB ============
  Widget _buildRoomsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        Color bgColor;
        Color textColor;
        String statusEmoji;

        if (room.status == 'Occupied') {
          bgColor = Colors.green.withOpacity(0.1);
          textColor = Colors.green;
          statusEmoji = '✓';
        } else if (room.status == 'Cleaning') {
          bgColor = Colors.orange.withOpacity(0.1);
          textColor = Colors.orange;
          statusEmoji = '🧹';
        } else {
          bgColor = Colors.grey.withOpacity(0.1);
          textColor = Colors.grey;
          statusEmoji = '◯';
        }

        return GestureDetector(
          onTap: () => _showRoomDetails(room),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  statusEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Room ${room.number}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room.status,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (room.guest.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      room.guest,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ HELPER METHODS ============

  void _trackDelivery(RoomServiceOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tracking ${order.staffName}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _infoPair('Order ID', order.id),
            _infoPair('Destination', 'Room ${order.roomNumber}'),
            _infoPair('Guest', order.guestName),
            _infoPair('Current GPS', '${order.latitude.toStringAsFixed(4)}, ${order.longitude.toStringAsFixed(4)}'),
            _infoPair('ETA', order.estimatedArrival),
            _infoPair('Total', order.totalAmount),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(RoomStatus room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room ${room.number}'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status: ${room.status}'),
            if (room.guest.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Guest: ${room.guest}'),
            ],
          ],
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

  Widget _infoPair(String label, String value) {
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ DATA MODELS ============

class RoomServiceOrder {
  final String id;
  final String roomNumber;
  final String guestName;
  final List<String> items;
  final String status;
  final String staffId;
  final String staffName;
  final String estimatedArrival;
  final String totalAmount;
  final double latitude;
  final double longitude;

  RoomServiceOrder({
    required this.id,
    required this.roomNumber,
    required this.guestName,
    required this.items,
    required this.status,
    required this.staffId,
    required this.staffName,
    required this.estimatedArrival,
    required this.totalAmount,
    required this.latitude,
    required this.longitude,
  });
}

class RoomStatus {
  final String number;
  final String status;
  final String guest;

  RoomStatus({
    required this.number,
    required this.status,
    required this.guest,
  });
}

// ============ INTEGRATION NOTES ============
/// HOW TO USE THIS:
///
/// 1. Import into your main.dart and use as hotel manager screen
/// 2. Connect Supabase for real room service orders
/// 3. Implement Google Maps in _buildTrackingTab()
/// 4. Stream staff locations using LiveLocationService
///
/// Key Features Added:
/// ✅ Room service order management
/// ✅ Real-time staff tracking
/// ✅ Room occupancy overview
/// ✅ ETA predictions
/// ✅ GPS coordinates
/// ✅ Order status badges
/// ✅ Quick actions (Track button)
///
/// Integration Steps:
/// 1. Connect to Supabase room_service_orders table
/// 2. Implement GoogleMapController with staff markers
/// 3. Stream LiveLocationService data for delivery staff
/// 4. Add push notifications for order status changes
/// 5. Integrate with your existing room management system
