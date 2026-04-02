import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../main.dart';

class RestaurantDashboardPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantDashboardPage({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  _RestaurantDashboardPageState createState() =>
      _RestaurantDashboardPageState();
}

class _RestaurantDashboardPageState extends State<RestaurantDashboardPage> {
  late StreamSubscription _orderStreamSubscription;
  List<FoodOrder> _restaurantOrders = [];
  int _newOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _setupOrdersListener();
  }

  void _setupOrdersListener() {
    print('👂 [DASHBOARD] Listening to orders for ${widget.restaurantId}');
    _orderStreamSubscription = AppServices.orderService
        .subscribeToRestaurantOrders(widget.restaurantId)
        .listen((orders) {
      setState(() {
        _restaurantOrders = orders;
        _newOrdersCount =
            orders.where((o) => o.status == OrderStatus.pending).length;
      });

      // Count new pending orders
      final newPendingCount = orders
          .where((o) => o.status == OrderStatus.pending)
          .toList()
          .length;

      if (newPendingCount > 0) {
        print('🔔 [ALERT] ${newPendingCount} new orders!');
        _playNotificationSound();
      }
    });
  }

  void _playNotificationSound() {
    // In production: integrate with audio plugin
    print('🔔 [SOUND] Playing notification...');
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await AppServices.orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.accepted,
      );
      _showSnackBar('✅ Order accepted', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _startPrep(String orderId) async {
    try {
      await AppServices.orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.preparing,
      );
      _showSnackBar('🍳 Started preparing', Colors.orange);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _markReady(String orderId) async {
    try {
      await AppServices.orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.ready,
      );
      _showSnackBar('✨ Order ready for pickup', Colors.blue);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order?'),
        content: Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AppServices.orderService.cancelOrder(
                  orderId: orderId,
                  reason: 'Cancelled by restaurant',
                );
                _showSnackBar('❌ Order cancelled', Colors.red);
              } catch (e) {
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          if (_newOrdersCount > 0)
            Container(
              margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$_newOrdersCount New',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _restaurantOrders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _restaurantOrders.length,
              itemBuilder: (context, index) {
                final order = _restaurantOrders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Orders will appear here when customers place them',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(FoodOrder order) {
    final statusColor = _getOrderColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
          ),
          color: statusColor.withOpacity(0.05),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$statusIcon Order #${order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        order.customerName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),

              // Items
              Text(
                '📋 Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  '• ${item.quantity}x ${item.name}',
                  style: TextStyle(fontSize: 12),
                ),
              )),

              // Special instructions
              if (order.specialInstructions != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.yellow.shade300),
                  ),
                  child: Text(
                    '⚠️ Special: ${order.specialInstructions}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.yellow.shade900,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 12),

              // Bus arrival time
              if (order.estimatedBusArrivalTime != null) ...[
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bus arrives in: ${order.estimatedBusArrivalTime!.difference(DateTime.now()).inMinutes} min',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Customer info
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Customer Contact:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      order.customerPhoneNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Order total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'K${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (order.status == OrderStatus.pending)
                    ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order.id),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (order.status == OrderStatus.accepted)
                    ElevatedButton.icon(
                      onPressed: () => _startPrep(order.id),
                      icon: Icon(Icons.local_fire_department, size: 18),
                      label: Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (order.status == OrderStatus.preparing)
                    ElevatedButton.icon(
                      onPressed: () => _markReady(order.id),
                      icon: Icon(Icons.done_all, size: 18),
                      label: Text('Ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (order.status != OrderStatus.completed &&
                      order.status != OrderStatus.cancelled)
                    ElevatedButton.icon(
                      onPressed: () => _cancelOrder(order.id),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOrderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.red;
      case OrderStatus.accepted:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.yellow;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.blue;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '🔴';
      case OrderStatus.accepted:
        return '🟠';
      case OrderStatus.preparing:
        return '🍳';
      case OrderStatus.ready:
        return '✅';
      case OrderStatus.completed:
        return '✨';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  @override
  void dispose() {
    _orderStreamSubscription.cancel();
    super.dispose();
  }
}
