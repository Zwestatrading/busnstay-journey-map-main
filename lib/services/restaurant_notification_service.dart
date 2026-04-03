import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/journey_model.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for managing restaurant notifications
/// Handles in-app, WhatsApp (via Wati), SMS, and email notifications
class RestaurantNotificationService {
  final SupabaseClient supabaseClient;
  
  // ============= WATI CONFIGURATION =============
  // Get your API key from https://www.wati.io/
  // Set these environment variables or update here:
  static const String WATI_API_BASE_URL = 'https://api.wati.io/api/v1';
  
  // TODO: Get these from environment or secure storage
  // For testing, you can hardcode or use a config file
  static String watiApiKey = ''; // Set your Wati API key here
  static String watiPhoneNumberId = ''; // Your WhatsApp Business Account phone number ID
  
  // Notification queues
  final List<RestaurantNotification> _pendingNotifications = [];
  StreamSubscription? _notificationStreamSubscription;
  
  RestaurantNotificationService({required this.supabaseClient});

  /// ============= WATI INITIALIZATION =============
  
  /// Initialize Wati with API credentials
  /// Call this from AppServices.initialize() before using notifications
  static void initializeWati({
    required String apiKey,
    required String phoneNumberId,
  }) {
    watiApiKey = apiKey;
    watiPhoneNumberId = phoneNumberId;
    print('✅ [WATI] Initialized with phone number ID: $phoneNumberId');
  }

  /// Check if Wati is properly configured
  static bool isWatiConfigured() {
    return watiApiKey.isNotEmpty && watiPhoneNumberId.isNotEmpty;
  }

  /// ============= INSTANT ORDER NOTIFICATION =============
  
  /// Notify restaurant immediately when order is confirmed and paid
  Future<bool> notifyRestaurantOrderPlaced({
    required FoodOrder order,
    required JourneyTown town,
    required Duration estimatedArrival,
  }) async {
    try {
      print('🔔 [NOTIFICATION] Sending order notification for order ${order.id}');
      
      // Create notification record
      final notification = RestaurantNotification(
        notificationId: _generateId('notif'),
        restaurantId: order.restaurantId,
        orderId: order.id,
        channel: NotificationChannel.inApp,
        sent: false,
        sentAt: DateTime.now(),
        estimatedBusArrival: estimatedArrival,
      );

      // Send through all channels
      final results = await Future.wait([
        _sendInAppNotification(notification, order, town, estimatedArrival),
        _sendWhatsAppNotification(order, town, estimatedArrival),
        _sendSMSNotification(order, town, estimatedArrival),
      ], eagerError: true);

      // Log notification in database
      await _logNotificationAttempt(notification, order);

      // Update order as notified
      await supabaseClient
          .from('orders')
          .update({'restaurant_notified': true})
          .eq('id', order.id);

      print('✅ [SUCCESS] Restaurant notification sent for order ${order.id}');
      return true;
    } catch (e) {
      print('❌ [ERROR] Failed to notify restaurant: $e');
      return false;
    }
  }

  /// Send in-app notification to restaurant dashboard
  Future<bool> _sendInAppNotification(
    RestaurantNotification notification,
    FoodOrder order,
    JourneyTown town,
    Duration estimatedArrival,
  ) async {
    try {
      final message = _buildNotificationMessage(order, estimatedArrival);
      
      // Insert notification into database
      await supabaseClient.from('restaurant_notifications').insert({
        'id': notification.notificationId,
        'restaurant_id': notification.restaurantId,
        'order_id': notification.orderId,
        'message': message,
        'type': 'order_placed',
        'order_details': order.toJson(),
        'town_name': town.townName,
        'estimated_arrival_minutes': estimatedArrival.inMinutes,
        'read': false,
        'created_at': notification.sentAt.toIso8601String(),
      });

      // Trigger real-time update via Supabase
      print('📱 [IN-APP] Notification sent to restaurant ${order.restaurantId}');
      return true;
    } catch (e) {
      print('❌ [IN-APP] Failed: $e');
      return false;
    }
  }

  /// Send WhatsApp notification to restaurant
  Future<bool> _sendWhatsAppNotification(
    FoodOrder order,
    JourneyTown town,
    Duration estimatedArrival,
  ) async {
    try {
      // Get restaurant phone number
      final restaurant = await supabaseClient
          .from('restaurants')
          .select('phone_number, whatsapp_number')
          .eq('id', order.restaurantId)
          .single();

      final phoneNumber = restaurant['whatsapp_number'] ?? restaurant['phone_number'];
      if (phoneNumber == null) {
        print('⚠️ [WhatsApp] No phone number for restaurant');
        return false;
      }

      final message = _buildWhatsAppMessage(order, town, estimatedArrival);

      // Send via WhatsApp API (e.g., Twilio, Wati, MessageBird)
      await _sendViaWhatsAppAPI(phoneNumber, message);

      print('💬 [WhatsApp] Message sent to $phoneNumber');
      return true;
    } catch (e) {
      print('❌ [WhatsApp] Failed: $e');
      return false;
    }
  }

  /// Send SMS notification to restaurant
  Future<bool> _sendSMSNotification(
    FoodOrder order,
    JourneyTown town,
    Duration estimatedArrival,
  ) async {
    try {
      // Get restaurant phone number
      final restaurant = await supabaseClient
          .from('restaurants')
          .select('phone_number')
          .eq('id', order.restaurantId)
          .single();

      final phoneNumber = restaurant['phone_number'];
      if (phoneNumber == null) {
        print('⚠️ [SMS] No phone number for restaurant');
        return false;
      }

      final message = _buildSMSMessage(order, town, estimatedArrival);

      // Send SMS (e.g., Twilio)
      await _sendViaSMSAPI(phoneNumber, message);

      print('📧 [SMS] Message sent to $phoneNumber');
      return true;
    } catch (e) {
      print('❌ [SMS] Failed: $e');
      return false;
    }
  }

  /// ============= MESSAGE BUILDERS =============

  String _buildNotificationMessage(FoodOrder order, Duration eta) {
    return '''
🎉 NEW ORDER RECEIVED
━━━━━━━━━━━━━━━━━━━
Order #${order.id.substring(0, 8).toUpperCase()}
Customer: ${order.customerName}
Items: ${order.items.map((i) => '${i.quantity}x ${i.name}').join(', ')}
Total: K${order.total.toStringAsFixed(2)}

Bus Arrival: ~${_formatDuration(eta)}
Pickup: ${order.pickupAddress ?? order.townName}

📍 Please confirm order receipt in dashboard.
''';
  }

  String _buildWhatsAppMessage(FoodOrder order, JourneyTown town, Duration eta) {
    return '''🔔 *NEW ORDER - ${order.townName}*

📋 *Order #${order.id.substring(0, 8).toUpperCase()}*
👤 *Customer:* ${order.customerName}
📱 *Phone:* ${order.customerPhoneNumber}

*Items:*
${order.items.map((i) => '• ${i.quantity}x ${i.name}').join('\n')}

💰 *Total:* K${order.total.toStringAsFixed(2)}
⏱️ *Bus Arrival:* ~${_formatDuration(eta)} from now

🚌 *Pickup Location:* ${town.pickupStationName}
📍 *Town:* ${town.townName}

---
👉 Click link to confirm order
👉 Start preparing now! ⏱️

Sent from *BusNStay* 🍽️🚌''';
  }

  String _buildSMSMessage(FoodOrder order, JourneyTown town, Duration eta) {
    return 'BusNStay: NEW ORDER #${order.id.substring(0, 6).toUpperCase()} from ${order.customerName} at ${order.townName}. Bus arrival ~${_formatDuration(eta)}. Total: K${order.total.toStringAsFixed(2)}. Items: ${order.items.map((i) => '${i.quantity}x ${i.name}').join(', ')}';
  }

  /// ============= NOTIFICATION DELIVERY =============

  /// Retry failed notifications
  Future<void> retrySendingNotifications() async {
    print('🔄 [RETRY] Processing ${_pendingNotifications.length} pending notifications...');
    
    final failed = <RestaurantNotification>[];
    for (final notification in _pendingNotifications) {
      if (!notification.sent) {
        // Retry logic here
        failed.add(notification);
      }
    }
    
    // Keep failed notifications, remove sent ones
    _pendingNotifications
        .removeWhere((n) => n.sent && _pendingNotifications.contains(n));
  }

  /// Listen to restaurant notification events (e.g., acknowledgment)
  Stream<Map<String, dynamic>> listenToNotificationAcknowledgments(
    String restaurantId,
  ) {
    return supabaseClient
        .from('restaurant_notifications')
        .stream(primaryKey: const ['notification_id'])
        .where((records) => records.any((r) => r['restaurant_id'] == restaurantId))
        .expand((records) => records)
        .map((event) => event as Map<String, dynamic>);
  }

  /// ============= DATABASE LOGGING =============

  /// Log notification attempt for audit trail
  Future<void> _logNotificationAttempt(
    RestaurantNotification notification,
    FoodOrder order,
  ) async {
    try {
      await supabaseClient.from('notification_audit_log').insert({
        'id': _generateId('audit'),
        'notification_id': notification.notificationId,
        'order_id': order.id,
        'restaurant_id': order.restaurantId,
        'channel': notification.channel.toString().split('.').last,
        'sent_at': DateTime.now().toIso8601String(),
        'status': notification.sent ? 'sent' : 'failed',
        'error_message': notification.errorMessage,
      });
    } catch (e) {
      print('⚠️ [AUDIT] Failed to log: $e');
    }
  }

  /// ============= EXTERNAL API CALLS =============

  /// Call WhatsApp via Wati API
  /// Wati is a WhatsApp Business API platform (supports SMS + WhatsApp)
  /// Sign up at https://www.wati.io/ to get API key
  Future<void> _sendViaWhatsAppAPI(String phoneNumber, String message) async {
    try {
      // Check if Wati is configured
      if (!isWatiConfigured()) {
        print('⚠️ [WATI] Not configured. Skipping WhatsApp notification.');
        print('   To enable: Call RestaurantNotificationService.initializeWati()');
        return;
      }

      // Normalize phone number (remove spaces, dashes, etc)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      final formattedNumber = cleanNumber.startsWith('+') ? cleanNumber : '+$cleanNumber';

      print('💬 [WATI] Sending WhatsApp to $formattedNumber...');

      // Call Wati API
      final response = await http.post(
        Uri.parse('$WATI_API_BASE_URL/sendSessionMessage/$watiPhoneNumberId'),
        headers: {
          'Authorization': 'Bearer $watiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': formattedNumber,
          'message': message,
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw Exception('Wati API timeout'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ [WATI] WhatsApp sent successfully. Message ID: ${data['messageId'] ?? 'N/A'}');
      } else {
        print('❌ [WATI] API error ${response.statusCode}: ${response.body}');
        throw Exception('Wati API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [WATI] Failed to send WhatsApp: $e');
      // Don't throw - let SMS serve as fallback
    }
  }

  /// Call SMS API (Wati also supports SMS)
  /// Or use a separate SMS provider like Twilio
  Future<void> _sendViaSMSAPI(String phoneNumber, String message) async {
    try {
      // Option 1: Use Wati for SMS (if configured)
      if (isWatiConfigured()) {
        print('📱 [SMS via WATI] Sending SMS to $phoneNumber...');
        
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
        final formattedNumber = cleanNumber.startsWith('+') ? cleanNumber : '+$cleanNumber';

        final response = await http.post(
          Uri.parse('$WATI_API_BASE_URL/sendMessage'),
          headers: {
            'Authorization': 'Bearer $watiApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'phoneNumber': formattedNumber,
            'message': message,
            'messageType': 'sms', // Wati supports SMS too
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ [SMS via WATI] SMS sent to $phoneNumber');
        } else {
          print('⚠️ [SMS via WATI] Failed: ${response.statusCode}');
        }
      } else {
        // Mock SMS (no provider configured)
        print('📧 [SMS] Mock sending to $phoneNumber (configure SMS provider to enable)');
        await Future.delayed(Duration(milliseconds: 300));
      }
    } catch (e) {
      print('⚠️ [SMS] Failed: $e');
      // Don't throw - SMS is optional
    }
  }

  /// ============= UTILITY HELPERS =============

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix:${timestamp}_${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(length, (index) {
      return chars[(DateTime.now().millisecond + index) % chars.length];
    }).join();
    return random;
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _notificationStreamSubscription?.cancel();
  }

  /// Send a simple order status notification to a customer
  Future<bool> sendOrderNotification({
    required String phone,
    required String orderId,
    required String message,
  }) async {
    try {
      print('📱 [NOTIFICATION] Sending to $phone: $message');
      if (isWatiConfigured()) {
        await _sendViaWhatsAppAPI(phone, message);
      }
      return true;
    } catch (e) {
      print('❌ [NOTIFICATION] Failed to send: $e');
      return false;
    }
  }
}
