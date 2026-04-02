enum OrderStatus { 
  pending, 
  accepted, 
  preparing, 
  ready, 
  completed, 
  cancelled 
}

enum NotificationChannel {
  inApp,
  whatsApp,
  sms,
  email,
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? specialRequest;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.specialRequest,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'specialRequest': specialRequest,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    price: (json['price'] as num).toDouble(),
    specialRequest: json['specialRequest'] as String?,
  );
}

class RestaurantNotification {
  final String notificationId;
  final String restaurantId;
  final String orderId;
  final NotificationChannel channel;
  final bool sent;
  final DateTime sentAt;
  final DateTime? acknowledgedAt;
  final String? errorMessage;
  final Duration estimatedBusArrival;

  RestaurantNotification({
    required this.notificationId,
    required this.restaurantId,
    required this.orderId,
    required this.channel,
    required this.sent,
    required this.sentAt,
    this.acknowledgedAt,
    this.errorMessage,
    required this.estimatedBusArrival,
  });

  String get statusLabel => sent ? 'Sent' : 'Failed';

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'restaurantId': restaurantId,
    'orderId': orderId,
    'channel': channel.toString().split('.').last,
    'sent': sent,
    'sentAt': sentAt.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'estimatedBusArrival': estimatedBusArrival.inMinutes,
  };

  factory RestaurantNotification.fromJson(Map<String, dynamic> json) =>
      RestaurantNotification(
        notificationId: json['notificationId'] as String,
        restaurantId: json['restaurantId'] as String,
        orderId: json['orderId'] as String,
        channel: _parseNotificationChannel(json['channel'] as String),
        sent: json['sent'] as bool,
        sentAt: DateTime.parse(json['sentAt'] as String),
        acknowledgedAt: json['acknowledgedAt'] != null
            ? DateTime.parse(json['acknowledgedAt'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
        estimatedBusArrival:
            Duration(minutes: json['estimatedBusArrival'] as int),
      );
}

class FoodOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhoneNumber;
  final String restaurantId;
  final String restaurantName;
  final String townId;
  final String townName;
  final String journeyId;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime orderTime;
  final DateTime? confirmedPaymentTime;
  final String? specialInstructions;
  final double deliveryFee;
  final double platformFee;
  
  // Restaurant notification tracking
  final List<RestaurantNotification> notifications;
  final DateTime? estimatedBusArrivalTime;
  final bool restaurantNotified;
  final String? deliveryAddress;
  final String? pickupAddress;

  FoodOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhoneNumber,
    required this.restaurantId,
    required this.restaurantName,
    required this.townId,
    required this.townName,
    required this.journeyId,
    required this.items,
    required this.status,
    required this.orderTime,
    this.confirmedPaymentTime,
    this.specialInstructions,
    this.deliveryFee = 0,
    this.platformFee = 0,
    this.notifications = const [],
    this.estimatedBusArrivalTime,
    this.restaurantNotified = false,
    this.deliveryAddress,
    this.pickupAddress,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + deliveryFee + platformFee;

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'New Order';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get estimated prep time based on items
  Duration getEstimatedPrepTime() {
    if (items.isEmpty) return Duration.zero;
    final maxPrepTime = items
        .map((item) {
          // Assuming item names map to MenuItem prep times
          // This would need to be data-driven in production
          const prepTimes = {
            'Chicken': 20,
            'Beef': 25,
            'Fish': 18,
            'Pasta': 15,
            'Salad': 5,
            'Burger': 10,
            'Pizza': 20,
          };
          for (final key in prepTimes.keys) {
            if (item.name.contains(key)) {
              return prepTimes[key]!;
            }
          }
          return 15; // default
        })
        .reduce((max, time) => time > max ? time : max);
    return Duration(minutes: maxPrepTime);
  }

  /// Check if order should have been notified by now
  bool shouldHaveNotified() {
    return confirmedPaymentTime != null &&
        DateTime.now().difference(confirmedPaymentTime!).inSeconds >= 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhoneNumber': customerPhoneNumber,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'townId': townId,
    'townName': townName,
    'journeyId': journeyId,
    'items': items.map((i) => i.toJson()).toList(),
    'status': status.toString().split('.').last,
    'orderTime': orderTime.toIso8601String(),
    'confirmedPaymentTime': confirmedPaymentTime?.toIso8601String(),
    'specialInstructions': specialInstructions,
    'deliveryFee': deliveryFee,
    'platformFee': platformFee,
    'notifications': notifications.map((n) => n.toJson()).toList(),
    'estimatedBusArrivalTime': estimatedBusArrivalTime?.toIso8601String(),
    'restaurantNotified': restaurantNotified,
    'deliveryAddress': deliveryAddress,
    'pickupAddress': pickupAddress,
  };

  factory FoodOrder.fromJson(Map<String, dynamic> json) => FoodOrder(
    id: json['id'] as String,
    customerId: json['customerId'] as String,
    customerName: json['customerName'] as String,
    customerPhoneNumber: json['customerPhoneNumber'] as String,
    restaurantId: json['restaurantId'] as String,
    restaurantName: json['restaurantName'] as String,
    townId: json['townId'] as String,
    townName: json['townName'] as String,
    journeyId: json['journeyId'] as String,
    items: (json['items'] as List<dynamic>)
        .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    status: _parseOrderStatus(json['status'] as String),
    orderTime: DateTime.parse(json['orderTime'] as String),
    confirmedPaymentTime: json['confirmedPaymentTime'] != null
        ? DateTime.parse(json['confirmedPaymentTime'] as String)
        : null,
    specialInstructions: json['specialInstructions'] as String?,
    deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
    platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0,
    notifications: (json['notifications'] as List<dynamic>?)
            ?.map((n) => RestaurantNotification.fromJson(n as Map<String, dynamic>))
            .toList() ??
        [],
    estimatedBusArrivalTime: json['estimatedBusArrivalTime'] != null
        ? DateTime.parse(json['estimatedBusArrivalTime'] as String)
        : null,
    restaurantNotified: json['restaurantNotified'] as bool? ?? false,
    deliveryAddress: json['deliveryAddress'] as String?,
    pickupAddress: json['pickupAddress'] as String?,
  );
}

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String category;
  final double price;
  final String? description;
  final int prepTimeMinutes;
  final bool isAvailable;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    required this.prepTimeMinutes,
    this.isAvailable = true,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurantId': restaurantId,
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'prepTimeMinutes': prepTimeMinutes,
    'isAvailable': isAvailable,
    'imageUrl': imageUrl,
  };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    restaurantId: json['restaurantId'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String?,
    prepTimeMinutes: json['prepTimeMinutes'] as int,
    isAvailable: json['isAvailable'] as bool? ?? true,
    imageUrl: json['imageUrl'] as String?,
  );
}

// Helper functions

OrderStatus _parseOrderStatus(String status) {
  switch (status) {
    case 'pending':
      return OrderStatus.pending;
    case 'accepted':
      return OrderStatus.accepted;
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

NotificationChannel _parseNotificationChannel(String channel) {
  switch (channel) {
    case 'inApp':
      return NotificationChannel.inApp;
    case 'whatsApp':
      return NotificationChannel.whatsApp;
    case 'sms':
      return NotificationChannel.sms;
    case 'email':
      return NotificationChannel.email;
    default:
      return NotificationChannel.inApp;
  }
}
