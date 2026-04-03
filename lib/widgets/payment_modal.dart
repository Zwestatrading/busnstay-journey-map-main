import 'package:flutter/material.dart';
import '../models/wallet_model.dart';

class PaymentModal extends StatefulWidget {
  final String title;
  final double? amount;
  final bool showAmountInput;
  final Function(double amount, PaymentMethod method) onConfirm;

  const PaymentModal({
    Key? key,
    required this.title,
    this.amount,
    this.showAmountInput = true,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  int _step = 0; // 0=method, 1=details, 2=processing, 3=success
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;
  String _selectedChannel = 'mobile_money_mtn';
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _presetAmounts = [25.0, 50.0, 100.0, 250.0, 500.0];

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            // Progress
            Row(
              children: List.generate(4, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _step ? const Color(0xFF3B82F6) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            _buildStepContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildMethodStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildProcessingStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showAmountInput) ...[
          Text('Amount (K)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'K ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Enter amount',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _presetAmounts.map((a) => ActionChip(
              label: Text('K${a.toStringAsFixed(0)}'),
              onPressed: () => setState(() => _amountController.text = a.toStringAsFixed(0)),
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildMethodTile('MTN Mobile Money', 'Fastest for MTN Zambia users', Icons.phone_android, 'mobile_money_mtn'),
        _buildMethodTile('Airtel Money', 'Use Airtel wallet approval flow', Icons.sim_card_outlined, 'mobile_money_airtel'),
        _buildMethodTile('Zamtel Money', 'Zamtel mobile money collection', Icons.mobile_friendly_outlined, 'mobile_money_zamtel'),
        _buildMethodTile('Card', 'Visa and Mastercard', Icons.credit_card, 'card'),
        _buildMethodTile('Bank Transfer', 'Direct bank payment', Icons.account_balance, 'bank'),
        _buildMethodTile('USSD', 'Dial to pay', Icons.dialpad, 'ussd'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              setState(() => _step = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile(String title, String subtitle, IconData icon, String channel) {
    final selected = _selectedChannel == channel;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedChannel = channel;
        _selectedMethod = _methodForChannel(channel);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF3B82F6) : Colors.grey[300]!, width: selected ? 2 : 1),
          color: selected ? const Color(0xFF3B82F6).withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF3B82F6) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? const Color(0xFF3B82F6) : null)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }

  PaymentMethod _methodForChannel(String channel) {
    switch (channel) {
      case 'card':
        return PaymentMethod.card;
      case 'bank':
        return PaymentMethod.bankTransfer;
      case 'ussd':
        return PaymentMethod.ussd;
      default:
        return PaymentMethod.mobileMoney;
    }
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount'),
              Text('K ${_amountController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedMethod == PaymentMethod.mobileMoney) ...[
          Text('Phone Number', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixText: '+260 ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: _selectedChannel == 'mobile_money_mtn'
                  ? '96 or 76 XXX XXXX'
                  : _selectedChannel == 'mobile_money_airtel'
                      ? '97 or 77 XXX XXXX'
                      : '95 XXX XXXX',
            ),
          ),
        ] else if (_selectedMethod == PaymentMethod.card) ...[
          Text('Card Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(decoration: InputDecoration(labelText: 'Card Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(labelText: 'MM/YY', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
              const SizedBox(width: 12),
              Expanded(child: TextField(decoration: InputDecoration(labelText: 'CVV', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
            ],
          ),
        ] else ...[
          Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('You will be redirected to complete payment', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _processPayment() {
    setState(() => _step = 2);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final amount = double.tryParse(_amountController.text) ?? 0;
        widget.onConfirm(amount, _selectedMethod);
        setState(() => _step = 3);
      }
    });
  }

  Widget _buildProcessingStep() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF3B82F6)),
            SizedBox(height: 20),
            Text('Processing payment...', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Please wait', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 64),
            const SizedBox(height: 16),
            const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('K ${_amountController.text} has been processed', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
