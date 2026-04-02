import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/journey_model.dart';
import 'restaurant_notification_service.dart';
import 'town_order_management_service.dart';
import 'database_service.dart';

/// Main service for managing the complete order lifecycle
/// Integrates restaurant notifications and town status management
class OrderManagementService {
  final SupabaseClient supabaseClient;
  final DatabaseService databaseService;
  final RestaurantNotificationService notificationService;
  final TownOrderManagementService townService;

  OrderManagementService({
    required this.supabaseClient,
    required this.databaseService,
    required this.notificationService,
    required this.townService,
  });

  /// ============= ORDER CREATION & VALIDATION =============

  /// Create a new food order
  /// This is called when user adds items to cart
  Future<FoodOrder?> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String restaurantId,
    required String restaurantName,
    required String townId,
    required String townName,
    required String journeyId,
    required List<OrderItem> items,
    required double deliveryFee,
    String? specialInstructions,
    String? pickupAddress,
    String? deliveryAddress,
  }) async {
    try {
      print('📝 [ORDER] Creating order for $customerName');

      // Validate items not empty
      if (items.isEmpty) {
        throw Exception('Cannot create order with empty items');
      }

      // Calculate totals
      final subtotal =
          items.fold<double>(0, (sum, item) => sum + item.total);
      final platformFee = subtotal * 0.10; // 10% platform fee
      final total = subtotal + deliveryFee + platformFee;

      // Create order object
      FoodOrder order = FoodOrder(
        id: _generateId('order'),
        customerId: customerId,
        customerName: customerName,
        customerPhoneNumber: customerPhone,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        townId: townId,
        townName: townName,
        journeyId: journeyId,
        items: items,
        status: OrderStatus.pending,
        orderTime: DateTime.now(),
        specialInstructions: specialInstructions,
        deliveryFee: deliveryFee,
        platformFee: platformFee,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
      );

      // Calculate estimated arrival
      final town = await townService.getTownDetails(townId);
      if (town != null && town.etaToTown != null) {
        order = FoodOrder(
          id: order.id,
          customerId: order.customerId,
          customerName: order.customerName,
          customerPhoneNumber: order.customerPhoneNumber,
          restaurantId: order.restaurantId,
          restaurantName: order.restaurantName,
          townId: order.townId,
          townName: order.townName,
          journeyId: order.journeyId,
          items: order.items,
          status: order.status,
          orderTime: order.orderTime,
          specialInstructions: order.specialInstructions,
          deliveryFee: order.deliveryFee,
          platformFee: order.platformFee,
          estimatedBusArrivalTime:
              DateTime.now().add(town.etaToTown!),
          pickupAddress: order.pickupAddress,
          deliveryAddress: order.deliveryAddress,
        );
      }

      // Save to local database first
      await databaseService.insertOrder(order);

      print('✅ [ORDER] Order created: ${order.id}');
      return order;
    } catch (e) {
      print('❌ [ERROR] Failed to create order: $e');
      return null;
    }
  }

  /// ============= PAYMENT & CONFIRMATION =============

  /// Confirm payment and trigger restaurant notification
  /// This is called after successful payment via Flutterwave
  Future<bool> confirmPaymentAndNotify({
    required FoodOrder order,
    required String transactionReference,
    required double amountPaid,
  }) async {
    try {
      print('💳 [PAYMENT] Confirming payment for order ${order.id}');

      // Validate payment amount
      if (amountPaid < order.total) {
        throw Exception('Amount paid is less than total');
      }

      // Validate town is still available
      final townValid =
          await townService.validateOrderFor(townId: order.townId, order: order);
      if (!(townValid['valid'] as bool)) {
        print('🚫 [PAYMENT] Town no longer accepting orders: ${townValid['reason']}');
        return false;
      }

      // Update order with payment confirmation
      final updatedOrder = FoodOrder(
        id: order.id,
        customerId: order.customerId,
        customerName: order.customerName,
        customerPhoneNumber: order.customerPhoneNumber,
        restaurantId: order.restaurantId,
        restaurantName: order.restaurantName,
        townId: order.townId,
        townName: order.townName,
        journeyId: order.journeyId,
        items: order.items,
        status: OrderStatus.pending,
        orderTime: order.orderTime,
        confirmedPaymentTime: DateTime.now(),
        specialInstructions: order.specialInstructions,
        deliveryFee: order.deliveryFee,
        platformFee: order.platformFee,
        estimatedBusArrivalTime: order.estimatedBusArrivalTime,
        pickupAddress: order.pickupAddress,
        deliveryAddress: order.deliveryAddress,
      );

      // Save to Supabase
      await supabaseClient.from('orders').insert({
        'id': updatedOrder.id,
        'customer_id': updatedOrder.customerId,
        'customer_name': updatedOrder.customerName,
        'customer_phone': updatedOrder.customerPhoneNumber,
        'restaurant_id': updatedOrder.restaurantId,
        'restaurant_name': updatedOrder.restaurantName,
        'journey_id': updatedOrder.journeyId,
        'town_id': updatedOrder.townId,
        'town_name': updatedOrder.townName,
        'items': updatedOrder.items.map((i) => i.toJson()).toList(),
        'subtotal': updatedOrder.subtotal,
        'delivery_fee': updatedOrder.deliveryFee,
        'platform_fee': updatedOrder.platformFee,
        'total_amount': updatedOrder.total,
        'status': 'pending',
        'payment_confirmed_at': updatedOrder.confirmedPaymentTime?.toIso8601String(),
        'estimated_bus_arrival_time':
            updatedOrder.estimatedBusArrivalTime?.toIso8601String(),
        'special_instructions': updatedOrder.specialInstructions,
        'pickup_address': updatedOrder.pickupAddress,
        'delivery_address': updatedOrder.deliveryAddress,
        'created_at': updatedOrder.orderTime.toIso8601String(),
      });

      // Update local database
      await databaseService.insertOrder(updatedOrder);

      print('✅ [PAYMENT] Payment confirmed for ${updatedOrder.id}');

      // ============= INSTANT RESTAURANT NOTIFICATION =============
      print('🔔 [NOTIFY] Sending instant notification to restaurant...');

      final town = await townService.getTownDetails(order.townId);
      if (town != null && updatedOrder.estimatedBusArrivalTime != null) {
        final eta =
            updatedOrder.estimatedBusArrivalTime!.difference(DateTime.now());

        // Send notification (all channels in parallel)
        final notified = await notificationService.notifyRestaurantOrderPlaced(
          order: updatedOrder,
          town: town,
          estimatedArrival: eta,
        );

        if (!notified) {
          print('⚠️ [NOTIFY] Notification sending failed, will retry');
        }
      }

      return true;
    } catch (e) {
      print('❌ [ERROR] Payment confirmation failed: $e');
      return false;
    }
  }

  /// ============= ORDER STATUS UPDATES =============

  /// Update order status (for restaurant)
  Future<bool> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      print('📊 [STATUS] Updating order $orderId to $newStatus');

      await supabaseClient.from('orders').update({
        'status': newStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // Notify relevant parties of status change
      if (newStatus == OrderStatus.ready) {
        await _notifyOrderReady(orderId);
      }

      return true;
    } catch (e) {
      print('❌ [ERROR] Failed to update order status: $e');
      return false;
    }
  }

  /// Cancel order (non-refundable)
  Future<bool> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      print('❌ [CANCEL] Cancelling order $orderId: $reason');

      await supabaseClient.from('orders').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // Notify restaurant
      await supabaseClient
          .from('restaurant_notifications')
          .insert({
        'id': _generateId('notif'),
        'order_id': orderId,
        'notification_type': 'order_cancelled',
        'message': 'Order cancelled: $reason',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ [ERROR] Failed to cancel order: $e');
      return false;
    }
  }

  /// ============= ORDER QUERIES =============

  /// Get orders for a restaurant in a specific town
  Future<List<FoodOrder>> getRestaurantOrdersForTown({
    required String restaurantId,
    required String townId,
    required String journeyId,
  }) async {
    try {
      final response =
          await supabaseClient.from('orders').select().match({
        'restaurant_id': restaurantId,
        'town_id': townId,
        'journey_id': journeyId,
      }).order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((o) => FoodOrder.fromJson(o))
          .toList();
    } catch (e) {
      print('❌ [ERROR] Failed to fetch restaurant orders: $e');
      return [];
    }
  }

  /// Get customer's order history
  Future<List<FoodOrder>> getCustomerOrderHistory({
    required String customerId,
    int limit = 20,
  }) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((o) => FoodOrder.fromJson(o))
          .toList();
    } catch (e) {
      print('❌ [ERROR] Failed to fetch customer orders: $e');
      return [];
    }
  }

  /// Get single order details
  Future<FoodOrder?> getOrderDetails(String orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return FoodOrder.fromJson(response);
    } catch (e) {
      print('❌ [ERROR] Failed to fetch order details: $e');
      return null;
    }
  }

  /// ============= REAL-TIME SUBSCRIPTIONS =============

  /// Subscribe to order status changes
  Stream<FoodOrder> subscribeToOrderUpdates(String orderId) {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: const ['id'])
        .where((records) => records.any((r) => r['id'] == orderId))
        .expand((records) => records)
        .map((event) => FoodOrder.fromJson(event))
        .asyncMap((order) async {
      // Also update local database if applicable
      await databaseService.insertOrder(order);
      return order;
    });
  }

  /// Subscribe to all restaurant orders in real-time
  Stream<List<FoodOrder>> subscribeToRestaurantOrders(String restaurantId) {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: const ['id'])
        .where((records) => records.isNotEmpty)
        .map((records) => records
            .where((r) => r['restaurant_id'] == restaurantId)
            .map((r) => FoodOrder.fromJson(r))
            .toList());
  }

  /// ============= HELPER METHODS =============

  /// Notify customer that order is ready for pickup
  Future<void> _notifyOrderReady(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      if (order == null) return;

      // Here you would send notification to customer
      // (SMS, WhatsApp, in-app notification)
      print('📲 [NOTIFY] Order $orderId is ready for pickup');
    } catch (e) {
      print('⚠️ [NOTIFY] Failed to notify customer: $e');
    }
  }

  /// Generate unique ID
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix:${timestamp}_${_randomString(8)}';
  }

  /// Generate random string
  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (i) => chars[(DateTime.now().millisecond + i) % chars.length],
    ).join();
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await notificationService.dispose();
    await townService.dispose();
  }
}
