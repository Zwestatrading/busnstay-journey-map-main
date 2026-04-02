enum DeliveryStatus { available, accepted, pickedUp, inTransit, delivered, cancelled }

class DeliveryJob {
  final String id;
  final String pickupAddress;
  final String deliveryAddress;
  final double distance;
  final double fee;
  final String customerName;
  final String? customerPhone;
  final DeliveryStatus status;
  final DateTime createdAt;
  final String? itemDescription;

  DeliveryJob({
    required this.id,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.distance,
    required this.fee,
    required this.customerName,
    this.customerPhone,
    required this.status,
    required this.createdAt,
    this.itemDescription,
  });

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.available:
        return 'Available';
      case DeliveryStatus.accepted:
        return 'Accepted';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class BusJourney {
  final String id;
  final String origin;
  final String destination;
  final DateTime departure;
  final DateTime arrival;
  final double price;
  final int totalSeats;
  final int bookedSeats;
  final String busNumber;

  BusJourney({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.price,
    required this.totalSeats,
    required this.bookedSeats,
    required this.busNumber,
  });

  int get availableSeats => totalSeats - bookedSeats;
}
