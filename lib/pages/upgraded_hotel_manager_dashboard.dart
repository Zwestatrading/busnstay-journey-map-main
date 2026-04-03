import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/hotel_enhanced_service.dart';
import '../widgets/operations_tracking_board.dart';

class UpgradedHotelManagerDashboard extends StatefulWidget {
  final String hotelId;

  const UpgradedHotelManagerDashboard({Key? key, required this.hotelId})
    : super(key: key);

  @override
  State<UpgradedHotelManagerDashboard> createState() =>
      _UpgradedHotelManagerDashboardState();
}

class _UpgradedHotelManagerDashboardState
    extends State<UpgradedHotelManagerDashboard> {
  final ImagePicker _picker = ImagePicker();
  int _tabIndex = 0;
  late HotelEnhancedService _hotelService;
  bool _acceptingBookings = true;

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
      countdown: const Duration(minutes: 8),
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
      countdown: const Duration(minutes: 16),
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
      countdown: Duration.zero,
      totalAmount: 'K125.00',
      latitude: -12.8085,
      longitude: 28.2715,
    ),
  ];

  final List<RoomStatus> _rooms = [
    RoomStatus(
      number: '101',
      status: 'Occupied',
      guest: 'John Smith',
      roomType: 'Executive Suite',
      nightlyRate: 780,
    ),
    RoomStatus(
      number: '102',
      status: 'Occupied',
      guest: 'Emma Wilson',
      roomType: 'Deluxe Double',
      nightlyRate: 620,
    ),
    RoomStatus(
      number: '103',
      status: 'Vacant',
      guest: '',
      roomType: 'Deluxe Double',
      nightlyRate: 620,
    ),
    RoomStatus(
      number: '104',
      status: 'Occupied',
      guest: 'David Lee',
      roomType: 'Business Single',
      nightlyRate: 480,
    ),
    RoomStatus(
      number: '105',
      status: 'Cleaning',
      guest: '',
      roomType: 'Business Single',
      nightlyRate: 480,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _hotelService = HotelEnhancedService(supabase: Supabase.instance.client);
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
          _buildOperationalHeader(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton(0, 'Orders', Icons.room_service),
                _buildTabButton(1, 'Tracking', Icons.person_pin_circle),
                _buildTabButton(2, 'Rooms', Icons.door_sliding),
                _buildTabButton(3, 'Reports', Icons.insights_outlined),
              ],
            ),
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
    );
  }

  Widget _buildOperationalHeader() {
    final occupiedRooms = _rooms
        .where((room) => room.status == 'Occupied')
        .length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF14B8A6)],
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
                      'Hotel operations command',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mobile now surfaces the same booking readiness, room visibility, and service monitoring intent as the web dashboard.',
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
                    _acceptingBookings ? 'Accepting bookings' : 'Paused',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Switch.adaptive(
                    value: _acceptingBookings,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF14B8A6),
                    onChanged: (value) =>
                        setState(() => _acceptingBookings = value),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HotelStatusPill('${_orders.length} service orders'),
              _HotelStatusPill('$occupiedRooms occupied rooms'),
              _HotelStatusPill(
                _acceptingBookings
                    ? 'Check-in flow live'
                    : 'New reservations paused',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0:
        return _buildOrdersTab();
      case 1:
        return _buildTrackingTab();
      case 2:
        return _buildRoomsTab();
      default:
        return _buildReportsTab();
    }
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
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF14B8A6) : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              height: 2,
              width: 34,
              margin: const EdgeInsets.only(top: 8),
              color: const Color(0xFF14B8A6),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
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
                title: 'Room Service Sales',
                value: 'K7,420',
                subtitle: '18 fulfilled requests today',
                icon: Icons.room_service_outlined,
                color: Color(0xFF14B8A6),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Guest Satisfaction',
                value: '4.8/5',
                subtitle: 'Average service rating',
                icon: Icons.star_border,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._orders.map(_buildOrderCard),
      ],
    );
  }

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        'Room ${order.roomNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                ),
                CountdownBadge(
                  label: order.status == 'Preparing' ? 'Prep' : 'ETA',
                  duration: order.countdown,
                  color: statusColor,
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
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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
                  '${order.staffName} • ${order.status}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  order.totalAmount,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (order.status != 'Delivered') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _trackDelivery(order),
                  icon: const Icon(Icons.location_searching_outlined),
                  label: const Text('Track delivery'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTab() {
    final inDeliveryOrders = _orders
        .where((order) => order.status == 'In Delivery')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OperationsTrackingBoard(
          title: 'Room service live board',
          originLabel: 'Kitchen',
          destinationLabel: 'Guest room',
          accentColor: const Color(0xFF14B8A6),
          entities: inDeliveryOrders.isEmpty
              ? const [
                  TrackingBoardEntity(
                    id: 'empty',
                    label: 'No live deliveries',
                    status: 'Standby',
                    color: Color(0xFF14B8A6),
                    progress: 0.1,
                    detail:
                        'Staff will appear here as soon as orders are dispatched.',
                  ),
                ]
              : inDeliveryOrders
                    .asMap()
                    .entries
                    .map(
                      (entry) => TrackingBoardEntity(
                        id: entry.value.id,
                        label: 'Room ${entry.value.roomNumber}',
                        status: entry.value.staffName,
                        color: entry.key.isEven
                            ? const Color(0xFF14B8A6)
                            : const Color(0xFF3B82F6),
                        progress: 0.45 + (entry.key * 0.18),
                        detail:
                            '${entry.value.items.first} • ${entry.value.estimatedArrival} arrival window',
                      ),
                    )
                    .toList(),
        ),
        const SizedBox(height: 16),
        ...inDeliveryOrders.map(
          (order) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.staffName} → Room ${order.roomNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'GPS ${order.latitude.toStringAsFixed(4)}, ${order.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                CountdownBadge(
                  label: 'ETA',
                  duration: order.countdown,
                  color: const Color(0xFF14B8A6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Rooms and availability',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddRoomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Add room'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.98,
            ),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final room = _rooms[index];
              return GestureDetector(
                onTap: () => _showRoomDetails(room),
                child: _buildRoomCard(room),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(RoomStatus room) {
    final color = room.status == 'Occupied'
        ? Colors.green
        : room.status == 'Cleaning'
        ? Colors.orange
        : const Color(0xFF14B8A6);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.imageUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    room.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _roomImageFallback(color),
                  ),
                ),
              )
            else
              Expanded(child: _roomImageFallback(color)),
            const SizedBox(height: 10),
            Text(
              'Room ${room.number}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              room.roomType,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusPill(room.status, color),
                Text(
                  'K${room.nightlyRate.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            if (room.guest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                room.guest,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roomImageFallback(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Icon(Icons.hotel_outlined, color: color, size: 34)),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildReportsTab() {
    final occupiedRooms = _rooms
        .where((room) => room.status == 'Occupied')
        .length;
    final occupancyRate =
        (_rooms.isEmpty ? 0 : occupiedRooms / _rooms.length) * 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            const SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Monthly Revenue',
                value: 'K84,300',
                subtitle: 'Rooms + room service combined',
                icon: Icons.account_balance_wallet_outlined,
                color: Color(0xFF14B8A6),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Occupancy',
                value: '${occupancyRate.toStringAsFixed(0)}%',
                subtitle: '$occupiedRooms of ${_rooms.length} rooms occupied',
                icon: Icons.hotel_class_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Delivery Speed',
                value: '11 min',
                subtitle: 'Average room service handoff',
                icon: Icons.delivery_dining_outlined,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddRoomSheet() async {
    final roomNumberController = TextEditingController();
    final roomTypeController = TextEditingController(text: 'Deluxe Double');
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final capacityController = TextEditingController(text: '2');
    Uint8List? imageBytes;
    String? imageName;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add hotel room',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final image = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image == null) {
                          return;
                        }
                        final bytes = await image.readAsBytes();
                        setModalState(() {
                          imageBytes = bytes;
                          imageName = image.name;
                        });
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF14B8A6).withOpacity(0.26),
                          ),
                        ),
                        child: imageBytes == null
                            ? Center(
                                child: Text(
                                  'Tap to upload room image',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF14B8A6),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      imageBytes!,
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
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          imageName ?? 'Room image',
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
                    const SizedBox(height: 12),
                    _sheetField(roomNumberController, 'Room number'),
                    const SizedBox(height: 12),
                    _sheetField(roomTypeController, 'Room type'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetField(
                            priceController,
                            'Nightly rate',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _sheetField(
                            capacityController,
                            'Capacity',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      descriptionController,
                      'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final roomNumber = roomNumberController.text.trim();
                          final roomType = roomTypeController.text.trim();
                          final price = double.tryParse(
                            priceController.text.trim(),
                          );
                          final capacity =
                              int.tryParse(capacityController.text.trim()) ?? 2;

                          if (roomNumber.isEmpty ||
                              roomType.isEmpty ||
                              price == null) {
                            _showMessage(
                              'Enter room number, type, and price.',
                              true,
                            );
                            return;
                          }

                          String? imageUrl;
                          if (imageBytes != null) {
                            imageUrl = await _hotelService.uploadRoomImageBytes(
                              bytes: imageBytes!,
                              hotelId: widget.hotelId,
                              roomId: roomNumber,
                              extension: _resolveExtension(imageName),
                            );
                          }

                          await _hotelService.addRoom(
                            hotelId: widget.hotelId,
                            roomNumber: roomNumber,
                            roomType: roomType,
                            price: price,
                            capacity: capacity,
                            amenities: const ['WiFi', 'Breakfast'],
                            imageUrls: imageUrl == null ? const [] : [imageUrl],
                            description: descriptionController.text.trim(),
                          );

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _rooms.add(
                              RoomStatus(
                                number: roomNumber,
                                status: 'Vacant',
                                guest: '',
                                roomType: roomType,
                                nightlyRate: price,
                                imageUrl: imageUrl,
                              ),
                            );
                          });

                          Navigator.pop(context);
                          _showMessage('Room added successfully.', false);
                        },
                        child: const Text('Save room'),
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

  Widget _sheetField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _resolveExtension(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return 'jpg';
    }
    return fileName.split('.').last.toLowerCase();
  }

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
            _infoPair(
              'Current GPS',
              '${order.latitude.toStringAsFixed(4)}, ${order.longitude.toStringAsFixed(4)}',
            ),
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
            const SizedBox(height: 8),
            Text('Type: ${room.roomType}'),
            const SizedBox(height: 8),
            Text('Rate: K${room.nightlyRate.toStringAsFixed(0)}'),
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

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF14B8A6),
      ),
    );
  }
}

class RoomServiceOrder {
  final String id;
  final String roomNumber;
  final String guestName;
  final List<String> items;
  final String status;
  final String staffId;
  final String staffName;
  final String estimatedArrival;
  final Duration countdown;
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
    required this.countdown,
    required this.totalAmount,
    required this.latitude,
    required this.longitude,
  });
}

class RoomStatus {
  final String number;
  final String status;
  final String guest;
  final String roomType;
  final double nightlyRate;
  final String? imageUrl;

  RoomStatus({
    required this.number,
    required this.status,
    required this.guest,
    required this.roomType,
    required this.nightlyRate,
    this.imageUrl,
  });
}

class _HotelStatusPill extends StatelessWidget {
  final String label;

  const _HotelStatusPill(this.label);

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
