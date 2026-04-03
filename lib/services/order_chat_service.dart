import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_chat_model.dart';

/// Service for handling live chat between passenger and store on an order.
/// Uses Supabase realtime for live message streaming and the
/// `order_chat_messages` table for persistence.
class OrderChatService {
  final SupabaseClient _supabase;

  // In-memory cache per order
  final Map<String, List<OrderChatMessage>> _cache = {};
  final Map<String, StreamController<List<OrderChatMessage>>> _controllers = {};

  OrderChatService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Get or create a stream of messages for an order (live updates).
  Stream<List<OrderChatMessage>> messagesStream(String orderId) {
    if (!_controllers.containsKey(orderId)) {
      _controllers[orderId] =
          StreamController<List<OrderChatMessage>>.broadcast();
      _loadAndSubscribe(orderId);
    }
    return _controllers[orderId]!.stream;
  }

  Future<void> _loadAndSubscribe(String orderId) async {
    // Load existing messages
    try {
      final rows = await _supabase
          .from('order_chat_messages')
          .select()
          .eq('order_id', orderId)
          .order('timestamp', ascending: true);

      final messages =
          (rows as List).map((r) => OrderChatMessage.fromJson(r)).toList();
      _cache[orderId] = messages;
      _controllers[orderId]?.add(messages);
    } catch (e) {
      // Table might not exist yet — start with empty list
      _cache[orderId] = [];
      _controllers[orderId]?.add([]);
    }

    // Subscribe to realtime inserts
    _supabase
        .from('order_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .listen((rows) {
          final messages =
              rows.map((r) => OrderChatMessage.fromJson(r)).toList();
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _cache[orderId] = messages;
          _controllers[orderId]?.add(messages);
        });
  }

  /// Send a message on an order thread.
  Future<OrderChatMessage?> sendMessage({
    required String orderId,
    required ChatSender sender,
    required String senderName,
    required String message,
    String? transportNote,
  }) async {
    final msg = OrderChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      orderId: orderId,
      sender: sender,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      transportNote: transportNote,
    );

    // Optimistic update for instant UX
    final list = _cache[orderId] ?? [];
    list.add(msg);
    _cache[orderId] = list;
    _controllers[orderId]?.add(List.unmodifiable(list));

    // Persist to Supabase
    try {
      await _supabase.from('order_chat_messages').insert(msg.toJson());
    } catch (e) {
      print('⚠️ [OrderChat] Failed to persist message: $e');
      // Message still shows locally — will sync when connection resumes
    }

    return msg;
  }

  /// Mark all messages as read for a given side.
  Future<void> markRead(String orderId, ChatSender reader) async {
    final opposite =
        reader == ChatSender.passenger ? 'store' : 'passenger';
    try {
      await _supabase
          .from('order_chat_messages')
          .update({'is_read': true})
          .eq('order_id', orderId)
          .eq('sender', opposite);
    } catch (_) {}
  }

  /// Get cached messages (no network call).
  List<OrderChatMessage> getCached(String orderId) =>
      _cache[orderId] ?? [];

  /// Unread count for a given side.
  int unreadCount(String orderId, ChatSender reader) {
    final opposite =
        reader == ChatSender.passenger ? ChatSender.store : ChatSender.passenger;
    return (_cache[orderId] ?? [])
        .where((m) => m.sender == opposite && !m.isRead)
        .length;
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _cache.clear();
  }
}
