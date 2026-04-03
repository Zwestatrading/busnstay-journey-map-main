import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/operations_tracking_board.dart';

class UpgradedDeliveryAgentDashboard extends StatefulWidget {
  final String agentId;

  const UpgradedDeliveryAgentDashboard({
    Key? key,
    required this.agentId,
  }) : super(key: key);

  @override
  State<UpgradedDeliveryAgentDashboard> createState() =>
      _UpgradedDeliveryAgentDashboardState();
}

class _UpgradedDeliveryAgentDashboardState
    extends State<UpgradedDeliveryAgentDashboard> {
  int _tabIndex = 0;

  final List<DeliveryRun> _activeRuns = const [
    DeliveryRun(
      orderCode: 'DL-201',
      pickup: 'Zwesta Food Court',
      destination: 'Room 312',
      status: 'Picked up',
      customerName: 'Sarah Johnson',
      payout: 'K28.00',
      countdown: Duration(minutes: 7),
      progress: 0.72,
    ),
    DeliveryRun(
      orderCode: 'DL-202',
      pickup: 'Station Grill',
      destination: 'Bus 5 gate',
      status: 'Heading out',
      customerName: 'Catherine Lungu',
      payout: 'K22.00',
      countdown: Duration(minutes: 11),
      progress: 0.48,
    ),
  ];

  final List<DeliveryRun> _availableRuns = const [
    DeliveryRun(
      orderCode: 'DL-203',
      pickup: 'Metro Bites',
      destination: 'Hotel lobby',
      status: 'Ready',
      customerName: 'Isaac Phiri',
      payout: 'K18.00',
      countdown: Duration(minutes: 15),
      progress: 0.12,
    ),
    DeliveryRun(
      orderCode: 'DL-204',
      pickup: 'Town Chicken',
      destination: 'Platform C',
      status: 'Ready',
      customerName: 'Ruth Tembo',
      payout: 'K20.00',
      countdown: Duration(minutes: 19),
      progress: 0.08,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Agent Dashboard'),
        backgroundColor: const Color(0xFF3B82F6),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
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
                _buildTabButton(0, 'Active', Icons.delivery_dining),
                _buildTabButton(1, 'Available', Icons.assignment_outlined),
                _buildTabButton(2, 'Reports', Icons.bar_chart_outlined),
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
        return _buildActiveTab();
      case 1:
        return _buildAvailableTab();
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
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OperationsTrackingBoard(
          title: 'Delivery movement board',
          originLabel: 'Pickup',
          destinationLabel: 'Drop-off',
          accentColor: const Color(0xFF3B82F6),
          entities: _activeRuns
              .map(
                (run) => TrackingBoardEntity(
                  id: run.orderCode,
                  label: run.orderCode,
                  status: run.status,
                  color: const Color(0xFF3B82F6),
                  progress: run.progress,
                  detail: '${run.pickup} → ${run.destination}',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        ..._activeRuns.map((run) => _deliveryCard(run, true)),
      ],
    );
  }

  Widget _buildAvailableTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _availableRuns.map((run) => _deliveryCard(run, false)).toList(),
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
                title: 'Today Earnings',
                value: 'K246',
                subtitle: '9 completed deliveries',
                icon: Icons.payments_outlined,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Avg Delivery Time',
                value: '13 min',
                subtitle: 'Door-to-door average',
                icon: Icons.timer_outlined,
                color: Color(0xFF14B8A6),
              ),
            ),
            SizedBox(
              width: 170,
              child: ReportMetricCard(
                title: 'Acceptance Rate',
                value: '96%',
                subtitle: 'Accepted versus assigned',
                icon: Icons.thumb_up_alt_outlined,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _deliveryCard(DeliveryRun run, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${run.orderCode} • ${run.customerName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CountdownBadge(
                label: active ? 'ETA' : 'Pickup',
                duration: run.countdown,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${run.pickup} → ${run.destination}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                run.status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Text(
                run.payout,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14B8A6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeliveryRun {
  final String orderCode;
  final String pickup;
  final String destination;
  final String status;
  final String customerName;
  final String payout;
  final Duration countdown;
  final double progress;

  const DeliveryRun({
    required this.orderCode,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.customerName,
    required this.payout,
    required this.countdown,
    required this.progress,
  });
}