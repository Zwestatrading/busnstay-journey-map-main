/// Chat message model for order communication between passenger and store.
enum ChatSender { passenger, store }

class OrderChatMessage {
  final String id;
  final String orderId;
  final ChatSender sender;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? transportNote; // e.g. "Bus 3, Seat 14A - arriving 2:30 PM"

  OrderChatMessage({
    required this.id,
    required this.orderId,
    required this.sender,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.transportNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'sender': sender == ChatSender.passenger ? 'passenger' : 'store',
    'sender_name': senderName,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'is_read': isRead,
    'transport_note': transportNote,
  };

  factory OrderChatMessage.fromJson(Map<String, dynamic> json) {
    return OrderChatMessage(
      id: json['id'] as String,
      orderId: (json['order_id'] ?? json['orderId']) as String,
      sender: (json['sender'] ?? '') == 'store'
          ? ChatSender.store
          : ChatSender.passenger,
      senderName: (json['sender_name'] ?? json['senderName'] ?? 'Unknown') as String,
      message: json['message'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      transportNote: (json['transport_note'] ?? json['transportNote']) as String?,
    );
  }

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
