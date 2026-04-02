import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/journey_model.dart';
import '../main.dart'; // For AppServices

class OrderCheckoutPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String townId;
  final String townName;
  final String journeyId;
  final List<OrderItem> cartItems;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final double deliveryFee;
  final String? specialInstructions;
  final String? pickupAddress;
  final String? deliveryAddress;

  const OrderCheckoutPage({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    required this.townId,
    required this.townName,
    required this.journeyId,
    required this.cartItems,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.deliveryFee = 5.0,
    this.specialInstructions,
    this.pickupAddress,
    this.deliveryAddress,
  }) : super(key: key);

  @override
  _OrderCheckoutPageState createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  FoodOrder? _order;
  bool _isPaymentProcessing = false;
  String? _townAvailabilityMessage;
  bool _townOpen = true;

  @override
  void initState() {
    super.initState();
    _checkTownAvailability();
  }

  Future<void> _checkTownAvailability() async {
    try {
      final available =
          await AppServices.townService.isTownOrderingAvailable(widget.townId);
      setState(() {
        _townOpen = available;
        if (!available) {
          _townAvailabilityMessage = 'Orders for ${widget.townName} are currently closed';
        }
      });
    } catch (e) {
      print('⚠️ [ERROR] Failed to check town availability: $e');
    }
  }

  Future<void> _processPayment(BuildContext context) async {
    setState(() => _isPaymentProcessing = true);

    try {
      // Step 1: Create order (unpaid)
      print('📝 [CHECKOUT] Creating order...');
      _order = await AppServices.orderService.createOrder(
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        townId: widget.townId,
        townName: widget.townName,
        journeyId: widget.journeyId,
        items: widget.cartItems,
        deliveryFee: widget.deliveryFee,
        specialInstructions: widget.specialInstructions,
        pickupAddress: widget.pickupAddress,
        deliveryAddress: widget.deliveryAddress,
      );

      if (_order == null) throw Exception('Failed to create order');

      // Step 2: Process payment via Flutterwave (in production)
      // For demo: simulate payment success
      await Future.delayed(Duration(seconds: 2));
      final paymentSuccess = true; // In production: check Flutterwave response

      if (!paymentSuccess) throw Exception('Payment failed');

      // Step 3: Confirm payment and trigger notification
      print('💳 [CHECKOUT] Confirming payment and notifying restaurant...');
      final confirmed = await AppServices.orderService.confirmPaymentAndNotify(
        order: _order!,
        transactionReference: 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
        amountPaid: _order!.total,
      );

      if (confirmed) {
        print('✅ [SUCCESS] Order placed and restaurant notified!');
        if (mounted) {
          _showSuccessDialog(context, _order!);
        }
      } else {
        throw Exception('Payment confirmation failed');
      }
    } catch (e) {
      print('❌ [ERROR] Checkout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context, FoodOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Order Confirmed!'),
            SizedBox(height: 8),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '🔔 Restaurant ${order.restaurantName} has been notified!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'They will start preparing your order immediately.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 12),
                  Text(
                    '⏱️ Bus Arriving In:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (order.estimatedBusArrivalTime != null)
                    Text(
                      '${order.estimatedBusArrivalTime!.difference(DateTime.now()).inMinutes} minutes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  SizedBox(height: 12),
                  Text(
                    '📍 Pickup:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    order.pickupAddress ?? order.townName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '💰 Total:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'K${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cartItems
        .fold<double>(0, (sum, item) => sum + (item.quantity * item.price));
    final platformFee = subtotal * 0.10;
    final total = subtotal + widget.deliveryFee + platformFee;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Town Availability Alert
            if (!_townOpen)
              Container(
                color: Colors.red.shade50,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚫 Ordering Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'The bus is approaching this town. '
                                'Orders have been closed to allow restaurants to prepare.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Order Summary
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Items
                        ...widget.cartItems.asMap().entries.map((entry) {
                          final item = entry.value;
                          final isLast =
                              entry.key == widget.cartItems.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  justify: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.quantity}x ${item.name}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (item.specialRequest != null)
                                          Text(
                                            'Special: ${item.specialRequest}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade700,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      'K${item.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          );
                        }),

                        // Divider
                        Divider(height: 1),

                        // Breakdown
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal:',
                                      style:
                                          TextStyle(color: Colors.grey.shade600)),
                                  Text('K${subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery Fee:',
                                      style:
                                          TextStyle(color: Colors.grey.shade600)),
                                  Text('K${widget.deliveryFee.toStringAsFixed(2)}'),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Tooltip(
                                    message: 'Platform fee (10%)',
                                    child: Text(
                                      'Platform Fee:',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Text('K${platformFee.toStringAsFixed(2)}'),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'K${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
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

                  SizedBox(height: 20),

                  // Restaurant Info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant, color: Colors.blue.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.restaurantName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Pickup: ${widget.townName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _townOpen && !_isPaymentProcessing
                          ? () => _processPayment(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPaymentProcessing
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _townOpen
                                  ? 'Pay K${total.toStringAsFixed(2)}'
                                  : 'Orders Closed - Try Another Town',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
