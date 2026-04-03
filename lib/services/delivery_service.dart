import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryService {
  final SupabaseClient supabase;

  DeliveryService({required this.supabase});

  /// Get available deliveries for agents
  Future<List<Map<String, dynamic>>> getAvailableDeliveries() async {
    try {
      final response = await supabase
          .from('deliveries')
          .select('*, orders(*, restaurants(name))')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [DELIVERY] Error fetching available deliveries: $e');
      return [];
    }
  }

  /// Get deliveries assigned to a specific agent
  Future<List<Map<String, dynamic>>> getAgentDeliveries(String agentId) async {
    try {
      final response = await supabase
          .from('deliveries')
          .select('*, orders(*)')
          .eq('agent_id', agentId)
          .inFilter('status', ['accepted', 'in_transit', 'picked_up']);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [DELIVERY] Error fetching agent deliveries: $e');
      return [];
    }
  }

  /// Get agent earnings for a specific date
  Future<double> getAgentEarnings(String agentId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await supabase
          .from('deliveries')
          .select('fee')
          .eq('agent_id', agentId)
          .eq('status', 'delivered')
          .gte('delivered_at', '${dateStr}T00:00:00')
          .lte('delivered_at', '${dateStr}T23:59:59');

      final deliveries = List<Map<String, dynamic>>.from(response);
      return deliveries.fold<double>(
          0, (sum, d) => sum + ((d['fee'] as num?)?.toDouble() ?? 0));
    } catch (e) {
      print('❌ [DELIVERY] Error fetching earnings: $e');
      return 0;
    }
  }

  /// Accept a delivery
  Future<bool> acceptDelivery(
      String deliveryId, String agentId, String customerPhone) async {
    try {
      await supabase.from('deliveries').update({
        'agent_id': agentId,
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      print('✅ [DELIVERY] Delivery #$deliveryId accepted by $agentId');
      return true;
    } catch (e) {
      print('❌ [DELIVERY] Error accepting delivery: $e');
      return false;
    }
  }

  /// Mark delivery as delivered
  Future<bool> markDelivered(String deliveryId, String customerPhone) async {
    try {
      await supabase.from('deliveries').update({
        'status': 'delivered',
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      print('✅ [DELIVERY] Delivery #$deliveryId marked as delivered');
      return true;
    } catch (e) {
      print('❌ [DELIVERY] Error marking delivered: $e');
      return false;
    }
  }

  /// Cancel a delivery
  Future<bool> cancelDelivery(
      String deliveryId, String customerPhone, String reason) async {
    try {
      await supabase.from('deliveries').update({
        'status': 'cancelled',
        'cancel_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      print('✅ [DELIVERY] Delivery #$deliveryId cancelled: $reason');
      return true;
    } catch (e) {
      print('❌ [DELIVERY] Error cancelling delivery: $e');
      return false;
    }
  }

  /// Set agent online/offline status
  Future<void> setAgentOnline(String agentId, bool isOnline) async {
    try {
      await supabase.from('delivery_agents').upsert({
        'id': agentId,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ [DELIVERY] Error setting agent status: $e');
    }
  }

  /// Subscribe to real-time delivery updates
  RealtimeChannel subscribeToDelivery(String deliveryId) {
    return supabase
        .channel('delivery:$deliveryId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: deliveryId,
          ),
          callback: (payload) {
            print('🔔 [DELIVERY] Update: ${payload.newRecord}');
          },
        )
        .subscribe();
  }
}
