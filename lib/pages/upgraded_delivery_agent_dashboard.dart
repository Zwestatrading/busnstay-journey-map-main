import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/wallet_model.dart';
import '../services/app_state.dart';
import '../services/flutterwave_service.dart';
import '../widgets/payment_modal.dart';
import '../widgets/operations_tracking_board.dart';

class UpgradedDeliveryAgentDashboard extends StatefulWidget {
  final String agentId;

  const UpgradedDeliveryAgentDashboard({Key? key, required this.agentId})
    : super(key: key);

  @override
  State<UpgradedDeliveryAgentDashboard> createState() =>
      _UpgradedDeliveryAgentDashboardState();
}

class _UpgradedDeliveryAgentDashboardState
    extends State<UpgradedDeliveryAgentDashboard> {
  int _tabIndex = 0;
  bool _isOnline = true;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<AppState>().logout(),
        ),
        title: const Text('Delivery Agent Dashboard'),
        backgroundColor: const Color(0xFF3B82F6),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton(0, 'Active', Icons.delivery_dining),
                _buildTabButton(1, 'Available', Icons.assignment_outlined),
                _buildTabButton(
                  2,
                  'Wallet',
                  Icons.account_balance_wallet_outlined,
                ),
                _buildTabButton(3, 'Reports', Icons.bar_chart_outlined),
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
      case 2:
        return _buildWalletTab();
      default:
        return _buildReportsTab();
    }
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Delivery control',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: Switch.adaptive(
                      value: _isOnline,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF14B8A6),
                      onChanged: (value) => setState(() => _isOnline = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _DeliveryPill('${_activeRuns.length} active'),
              _DeliveryPill('${_availableRuns.length} ready'),
              _DeliveryPill(_isOnline ? 'GPS good' : 'Standby'),
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
          Icon(icon, color: isSelected ? const Color(0xFF3B82F6) : Colors.grey),
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

  Widget _buildWalletTab() {
    final appState = context.watch<AppState>();
    final wallet = appState.wallet;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkBg, Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rider wallet',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                FlutterwaveService.formatZMW(wallet.balance),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use the same wallet rails exposed in the web rider dashboard to manage payouts, transfers, and float.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _walletAction(
                'Add funds',
                Icons.add_circle_outline,
                const Color(0xFF14B8A6),
                _showAddFundsModal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _walletAction(
                'Transfer',
                Icons.send_outlined,
                const Color(0xFF7C3AED),
                _showTransferDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _walletAction(
                'Withdraw',
                Icons.savings_outlined,
                const Color(0xFFF59E0B),
                _showWithdrawDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Recent transactions',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...wallet.transactions.take(5).map(_buildTransactionTile),
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

  Widget _walletAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tx.icon, color: tx.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.method.name,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            FlutterwaveService.formatZMW(tx.amount),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: tx.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFundsModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentModal(
        title: 'Top up rider wallet',
        onConfirm: (amount, method) {
          context.read<AppState>().addFunds(amount, method);
        },
      ),
    );
  }

  Future<void> _showTransferDialog() async {
    final recipientController = TextEditingController(
      text: 'merchant@busnstay.com',
    );
    final amountController = TextEditingController(text: '80');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(labelText: 'Recipient'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (K)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              await context.read<AppState>().transferFunds(
                amount,
                recipientController.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController(text: '120');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw earnings'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (K)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              await context.read<AppState>().withdrawFunds(amount);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPill extends StatelessWidget {
  final String label;

  const _DeliveryPill(this.label);

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




