import 'package:supabase_flutter/supabase_flutter.dart';
import 'restaurant_notification_service.dart';

class RestaurantService {
  final SupabaseClient supabase;
  final RestaurantNotificationService notificationService;

  RestaurantService({
    required this.supabase,
    required this.notificationService,
  });

  // Get pending orders
  Future<List<Map<String, dynamic>>> getPendingOrders(String restaurantId) async {
    try {
      final response = await supabase
          .from('orders')
          .select('*, order_items(*, menu_items(*))')
          .eq('restaurant_id', restaurantId)
          .inFilter('status', ['pending', 'confirmed'])
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [ORDERS] Error fetching orders: $e');
      return [];
    }
  }

  // Accept order + notify customer via WATI
  Future<bool> acceptOrder(String orderId, String customerPhone) async {
    try {
      // Update order status
      await supabase
          .from('orders')
          .update({'status': 'accepted', 'accepted_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      // Send WhatsApp notification via WATI
      await notificationService.sendOrderNotification(
        phone: customerPhone,
        orderId: orderId,
        message: 'Your order #$orderId has been accepted! Preparing your meal... ✅',
      );

      print('✅ [ORDER] Order #$orderId accepted & customer notified');
      return true;
    } catch (e) {
      print('❌ [ORDER] Error accepting order: $e');
      return false;
    }
  }

  // Reject order + notify customer
  Future<bool> rejectOrder(String orderId, String customerPhone, String reason) async {
    try {
      await supabase
          .from('orders')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'rejected_at': DateTime.now().toIso8601String()
          })
          .eq('id', orderId);

      await notificationService.sendOrderNotification(
        phone: customerPhone,
        orderId: orderId,
        message: 'We\'re sorry, your order #$orderId was declined: $reason',
      );

      return true;
    } catch (e) {
      print('❌ [ORDER] Error rejecting order: $e');
      return false;
    }
  }

  // Mark order as ready
  Future<bool> markOrderReady(String orderId, String customerPhone) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'ready', 'ready_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      await notificationService.sendOrderNotification(
        phone: customerPhone,
        orderId: orderId,
        message: 'Your order #$orderId is ready for pickup! 🎉',
      );

      return true;
    } catch (e) {
      print('❌ [ORDER] Error marking order ready: $e');
      return false;
    }
  }

  // Get menu items
  Future<List<Map<String, dynamic>>> getMenuItems(String restaurantId) async {
    try {
      final response = await supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order('category');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [MENU] Error fetching menu: $e');
      return [];
    }
  }

  // Update menu item availability
  Future<bool> updateMenuItemAvailability(String itemId, bool isAvailable) async {
    try {
      await supabase
          .from('menu_items')
          .update({'is_available': isAvailable})
          .eq('id', itemId);

      return true;
    } catch (e) {
      print('❌ [MENU] Error updating menu item: $e');
      return false;
    }
  }

  // Get restaurant analytics
  Future<Map<String, dynamic>?> getAnalytics(String restaurantId, DateTime date) async {
    try {
      final dateStr = date.toString().split(' ')[0];
      final response = await supabase
          .from('order_analytics')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('date', dateStr)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ [ANALYTICS] Error fetching analytics: $e');
      return null;
    }
  }

  // Real-time order updates
  RealtimeChannel subscribeToOrders(String restaurantId) {
    return supabase
        .channel('orders:$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            print('🔔 [NEW ORDER] ${payload.newRecord}');
          },
        )
        .subscribe();
  }
}
