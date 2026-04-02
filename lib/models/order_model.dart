enum OrderStatus { pending, accepted, preparing, ready, completed, cancelled }

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});

  double get total => quantity * price;
}

class FoodOrder {
  final String id;
  final String customerName;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime orderTime;
  final String? specialInstructions;
  final double deliveryFee;

  FoodOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.status,
    required this.orderTime,
    this.specialInstructions,
    this.deliveryFee = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + deliveryFee;

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'New';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? description;
  final int prepTimeMinutes;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    required this.prepTimeMinutes,
    this.isAvailable = true,
  });
}
