enum BookingStatus { pending, confirmed, checkedIn, checkedOut, cancelled }

class HotelBooking {
  final String id;
  final String guestName;
  final String roomNumber;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double pricePerNight;
  final BookingStatus status;

  HotelBooking({
    required this.id,
    required this.guestName,
    required this.roomNumber,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.pricePerNight,
    required this.status,
  });

  int get nights => checkOut.difference(checkIn).inDays;
  double get totalPrice => nights * pricePerNight;

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class HotelRoom {
  final String id;
  final String number;
  final String type;
  final double pricePerNight;
  final int capacity;
  final bool isAvailable;
  final List<String> amenities;

  HotelRoom({
    required this.id,
    required this.number,
    required this.type,
    required this.pricePerNight,
    required this.capacity,
    required this.isAvailable,
    required this.amenities,
  });
}
