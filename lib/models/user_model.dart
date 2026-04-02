enum UserRole {
  passenger,
  busOperator,
  restaurantAdmin,
  deliveryAgent,
  hotelManager,
  platformAdmin,
  guest,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime memberSince;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.memberSince,
    this.avatarUrl,
  });
}
