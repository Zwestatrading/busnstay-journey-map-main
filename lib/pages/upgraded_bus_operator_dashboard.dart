import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/operations_tracking_board.dart';

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
  int _tabIndex = 0;

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
      countdown: const Duration(minutes: 12),
    ),
    BusVehicle(
      id: 'bus_002',
      registrationNumber: 'ZL-25-DEF-456',
      driverName: 'Patricia Banda',
      status: 'Boarding',
      destination: 'Ndola Station',
      latitude: -13.2005,
      longitude: 28.6352,
      passengersOnBoard: 28,
      capacity: 48,
      nextStop: 'Departure gate',
      eta: '15:00',
      countdown: const Duration(minutes: 22),
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
      countdown: const Duration(minutes: 0),
    ),
  ];

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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton(0, 'Fleet', Icons.directions_bus),
                _buildTabButton(1, 'Live Map', Icons.map_outlined),
                _buildTabButton(2, 'Routes', Icons.alt_route),
                _buildTabButton(3, 'Reports', Icons.query_stats),
              ],
            ),
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0:
        return _buildFleetTab();
      case 1:
        return _buildLiveMapTab();
      case 2:
        return _buildRoutesTab();
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
            color: isSelected ? const Color(0xFFFD5E14) : Colors.grey,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFFD5E14) : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              height: 2,
              width: 34,
              margin: const EdgeInsets.only(top: 8),
              color: const Color(0xFFFD5E14),
            ),
        ],
      ),
    );
  }

  Widget _buildFleetTab() {
    final activeCount = _buses.where((bus) => bus.status != 'Arrived').length;

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
                title: 'Fleet Online',
                value: '$activeCount / ${_buses.length}',
                subtitle: 'Vehicles currently moving or boarding',
                icon: Icons.directions_bus_filled_outlined,
                color: const Color(0xFFFD5E14),
              ),
            ),
            const SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Daily Ticket Sales',
                value: 'K18,920',
                subtitle: 'Across all active routes today',
                icon: Icons.payments_outlined,
                color: Color(0xFF14B8A6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._buses.map(_buildBusCard),
      ],
    );
  }

  Widget _buildBusCard(BusVehicle bus) {
    final statusColor = bus.status == 'In Transit'
        ? Colors.blue
        : bus.status == 'Boarding'
            ? Colors.orange
            : Colors.green;
    final occupancyPercent = bus.capacity == 0 ? 0.0 : bus.passengersOnBoard / bus.capacity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.16)),
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
                        bus.registrationNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${bus.driverName} • ${bus.destination}',
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
                  label: 'ETA',
                  duration: bus.countdown,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Next stop: ${bus.nextStop}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Passengers ${bus.passengersOnBoard}/${bus.capacity}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: occupancyPercent,
                minHeight: 7,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _trackBusLive(bus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFD5E14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.location_searching_outlined),
                label: const Text('Track bus live'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMapTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OperationsTrackingBoard(
          title: 'Uber-style fleet movement board',
          originLabel: 'Depot',
          destinationLabel: 'Destination',
          accentColor: const Color(0xFFFD5E14),
          entities: _buses
              .asMap()
              .entries
              .map(
                (entry) => TrackingBoardEntity(
                  id: entry.value.id,
                  label: entry.value.registrationNumber,
                  status: entry.value.status,
                  color: entry.value.status == 'Arrived'
                      ? Colors.green
                      : entry.value.status == 'Boarding'
                          ? Colors.orange
                          : const Color(0xFF3B82F6),
                  progress: entry.value.status == 'Arrived'
                      ? 0.96
                      : 0.32 + (entry.key * 0.2),
                  detail:
                      '${entry.value.driverName} • ${entry.value.nextStop} • ${entry.value.eta}',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buses
                .map(
                  (bus) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.registrationNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'GPS ${bus.latitude.toStringAsFixed(4)}, ${bus.longitude.toStringAsFixed(4)}',
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
                          duration: bus.countdown,
                          color: const Color(0xFFFD5E14),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesTab() {
    final routes = [
      {
        'name': 'Lusaka ↔ Ndola',
        'buses': '2 buses',
        'trips': '5 departures/day',
        'status': 'Active',
        'window': const Duration(minutes: 18),
      },
      {
        'name': 'Lusaka ↔ Kitwe',
        'buses': '1 bus',
        'trips': '3 departures/day',
        'status': 'Boarding',
        'window': const Duration(minutes: 28),
      },
      {
        'name': 'Ndola ↔ Kitwe',
        'buses': '1 bus',
        'trips': '2 departures/day',
        'status': 'Paused',
        'window': const Duration(minutes: 45),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        final label = route['status'] as String;
        final color = label == 'Active'
            ? Colors.green
            : label == 'Boarding'
                ? Colors.orange
                : Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.16)),
          ),
          child: Row(
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
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${route['buses']} • ${route['trips']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(label, color),
                  const SizedBox(height: 8),
                  CountdownBadge(
                    label: 'Next',
                    duration: route['window'] as Duration,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Monthly Revenue',
                value: 'K412,000',
                subtitle: 'Ticketing and cargo combined',
                icon: Icons.account_balance_wallet_outlined,
                color: Color(0xFFFD5E14),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'On-time Departures',
                value: '91%',
                subtitle: 'Across all active routes',
                icon: Icons.timelapse_outlined,
                color: Color(0xFF14B8A6),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Average Load',
                value: '82%',
                subtitle: 'Fleet occupancy this week',
                icon: Icons.people_outline,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
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

  void _trackBusLive(BusVehicle bus) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bus.registrationNumber,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Driver', bus.driverName),
            _detailRow('Destination', bus.destination),
            _detailRow('Next stop', bus.nextStop),
            _detailRow('GPS', '${bus.latitude.toStringAsFixed(4)}, ${bus.longitude.toStringAsFixed(4)}'),
            _detailRow('Passengers', '${bus.passengersOnBoard}/${bus.capacity}'),
            _detailRow('ETA', bus.eta),
          ],
        ),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  final Duration countdown;

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
    required this.countdown,
  });
}