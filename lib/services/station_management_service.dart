import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing bus stations and station-based services
/// Stations are pickup/dropoff points where restaurants, shops can register
class StationManagementService {
  final SupabaseClient supabase;

  StationManagementService({required this.supabase});

  // ===== STATION REGISTRATION =====

  /// Register a new bus station
  /// Returns: {'success': bool, 'id': String, 'message': String}
  Future<Map<String, dynamic>> registerStation({
    required String name,
    required double latitude,
    required double longitude,
    required String town,
    required String address,
    required String managerName,
    required String managerPhone,
    required String managerEmail,
    required List<String> facilities, // ['restaurant', 'shop', 'toilet', 'parking']
    required String photographUrl,
  }) async {
    try {
      final response = await supabase.from('bus_stations').insert({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'town': town,
        'address': address,
        'manager_name': managerName,
        'manager_phone': managerPhone,
        'manager_email': managerEmail,
        'facilities': facilities,
        'photograph_url': photographUrl,
        'status': 'pending_approval', // Not visible until approved
        'is_visible': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        return {
          'success': true,
          'id': response[0]['id'],
          'message':
              '✅ Station registered. It will appear on the map after admin approval.',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error registering station',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error registering station: $e',
      };
    }
  }

  /// Approve a station (admin only)
  Future<Map<String, dynamic>> approveStation({
    required String stationId,
    required String approverName,
  }) async {
    try {
      await supabase.from('bus_stations').update({
        'status': 'approved',
        'is_visible': true,
        'approved_at': DateTime.now().toIso8601String(),
        'approved_by': approverName,
      }).eq('id', stationId);

      print('✅ Station #$stationId APPROVED');
      return {
        'success': true,
        'message': '✅ Station approved and now visible',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error approving station: $e',
      };
    }
  }

  /// Get all approved stations on the map
  Future<List<Map<String, dynamic>>> getApprovedStations() async {
    try {
      final response = await supabase
          .from('bus_stations')
          .select()
          .eq('status', 'approved')
          .eq('is_visible', true)
          .order('town');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching stations: $e');
      return [];
    }
  }

  /// Get stations near a location
  Future<List<Map<String, dynamic>>> getNearbyStations({
    required double userLat,
    required double userLng,
    required double radiusKm,
  }) async {
    try {
      final response = await supabase
          .from('bus_stations')
          .select()
          .eq('status', 'approved')
          .eq('is_visible', true);

      final stations = List<Map<String, dynamic>>.from(response);

      // Filter by distance
      final nearby = stations.where((s) {
        double distance = _calculateDistance(
          userLat,
          userLng,
          s['latitude'] as double,
          s['longitude'] as double,
        );
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      nearby.sort((a, b) {
        double distA = _calculateDistance(
          userLat,
          userLng,
          a['latitude'] as double,
          a['longitude'] as double,
        );
        double distB = _calculateDistance(
          userLat,
          userLng,
          b['latitude'] as double,
          b['longitude'] as double,
        );
        return distA.compareTo(distB);
      });

      return nearby;
    } catch (e) {
      print('❌ Error fetching nearby stations: $e');
      return [];
    }
  }

  // ===== STATION SERVICES (Restaurants, Shops, etc) =====

  /// Add a service to a station (restaurant, shop, etc)
  /// Returns: {'success': bool, 'id': String}
  Future<Map<String, dynamic>> addStationService({
    required String stationId,
    required String serviceType, // 'restaurant', 'shop', 'cafe'
    required String name,
    required String ownerName,
    required String ownerPhone,
    required List<String> amenities,
    required String photographUrl,
  }) async {
    try {
      final response = await supabase.from('station_services').insert({
        'station_id': stationId,
        'service_type': serviceType,
        'name': name,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        'amenities': amenities,
        'photograph_url': photographUrl,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        return {
          'success': true,
          'id': response[0]['id'],
          'message': '✅ Service added to station',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error adding service',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error: $e',
      };
    }
  }

  /// Get services at a station
  Future<List<Map<String, dynamic>>> getStationServices(String stationId) async {
    try {
      final response = await supabase
          .from('station_services')
          .select()
          .eq('station_id', stationId)
          .eq('is_active', true)
          .order('service_type');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching station services: $e');
      return [];
    }
  }

  // ===== STATION ORDERS =====

  /// Get orders for a station service
  /// Used by restaurant/shop to see incoming orders
  Future<List<Map<String, dynamic>>> getStationServiceOrders({
    required String serviceId,
    required String status, // 'pending', 'confirmed', 'completed'
  }) async {
    try {
      final response = await supabase
          .from('station_orders')
          .select('*, order_items(*)')
          .eq('service_id', serviceId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return [];
    }
  }

  /// Create order for station service
  Future<Map<String, dynamic>> createStationOrder({
    required String serviceId,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> items, // [{item_name, quantity, price}, ...]
  }) async {
    try {
      double totalPrice = 0;
      for (var item in items) {
        totalPrice += (item['price'] as num) * (item['quantity'] as num);
      }

      final response = await supabase.from('station_orders').insert({
        'service_id': serviceId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': items,
        'total_price': totalPrice,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        final createdRecord = Map<String, dynamic>.from(response[0]);
        final createdAt = DateTime.tryParse(createdRecord['created_at']?.toString() ?? '') ??
            DateTime.now();
        return {
          'success': true,
          'id': createdRecord['id'],
          'order_number': _buildStationOrderNumber(
            createdRecord['id']?.toString() ?? '',
            createdAt,
          ),
          'total_price': totalPrice,
          'message': '✅ Order placed. Awaiting confirmation.',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error creating order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error: $e',
      };
    }
  }

  /// Accept order (service owner confirms they can prepare it)
  Future<bool> acceptStationOrder(String orderId) async {
    try {
      await supabase.from('station_orders').update({
        'status': 'confirmed',
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return true;
    } catch (e) {
      print('❌ Error accepting order: $e');
      return false;
    }
  }

  /// Mark order as ready
  Future<bool> markStationOrderReady(String orderId) async {
    try {
      await supabase.from('station_orders').update({
        'status': 'ready',
        'ready_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return true;
    } catch (e) {
      print('❌ Error marking ready: $e');
      return false;
    }
  }

  /// Complete order (customer picked it up)
  Future<bool> completeStationOrder(String orderId) async {
    try {
      await supabase.from('station_orders').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return true;
    } catch (e) {
      print('❌ Error completing order: $e');
      return false;
    }
  }

  // ===== STATION ANALYTICS =====

  /// Get station earnings
  Future<Map<String, dynamic>> getStationEarnings({
    required String serviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await supabase
          .from('station_orders')
          .select()
          .eq('service_id', serviceId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalEarnings = 0;
      for (final order in orders as List) {
        totalEarnings += (order['total_price'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_orders': (orders as List).length,
        'total_earnings': totalEarnings.toStringAsFixed(2),
        'period':
            '${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}',
      };
    } catch (e) {
      print('❌ Error fetching earnings: $e');
      return {
        'total_orders': 0,
        'total_earnings': '0',
      };
    }
  }

  /// Get station dashboard
  Future<Map<String, dynamic>> getStationDashboard(String stationId) async {
    try {
      final station =
          await supabase.from('bus_stations').select().eq('id', stationId).single();

      final services = await supabase
          .from('station_services')
          .select()
          .eq('station_id', stationId)
          .eq('is_active', true);

      final todayOrders = await supabase
          .from('station_orders')
          .select()
          .inFilter('status', ['confirmed', 'ready'])
          .gte('created_at', DateTime.now().toIso8601String().split('T')[0]);

      return {
        'station_name': station['name'],
        'location': station['address'],
        'active_services': (services as List).length,
        'pending_orders': (todayOrders as List).length,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error fetching dashboard: $e');
      return {
        'active_services': 0,
        'pending_orders': 0,
      };
    }
  }

  /// Calculate distance using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double sin(double value) => _sinImpl(value);
  static double cos(double value) => _cosImpl(value);
  static double sqrt(double value) => _sqrtImpl(value);
  static double atan2(double y, double x) => _atan2Impl(y, x);

  static double _toRad(double value) => value * (3.14159265359 / 180);

  String _buildStationOrderNumber(String id, DateTime createdAt) {
    final datePart =
        '${createdAt.year.toString().padLeft(4, '0')}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';
    final sanitized = id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final suffix = sanitized.length >= 4
        ? sanitized.substring(sanitized.length - 4)
        : sanitized.padLeft(4, '0');
    return 'SO-$datePart-$suffix';
  }

  static double _sinImpl(double x) {
    double result = x;
    double numerator = x;
    double denominator = 1.0;
    for (int i = 1; i <= 10; i++) {
      numerator *= -x * x;
      denominator *= (2 * i) * (2 * i + 1);
      result += numerator / denominator;
    }
    return result;
  }

  static double _cosImpl(double x) {
    double result = 1.0;
    double numerator = 1.0;
    double denominator = 1.0;
    for (int i = 1; i <= 10; i++) {
      numerator *= -x * x;
      denominator *= (2 * i - 1) * (2 * i);
      result += numerator / denominator;
    }
    return result;
  }

  static double _sqrtImpl(double n) {
    if (n < 0) return double.nan;
    if (n == 0) return 0;
    return _sqrtNewton(n, n / 2);
  }

  static double _sqrtNewton(double n, double x) {
    if ((x - n / x).abs() < 0.000001) return x;
    return _sqrtNewton(n, (x + n / x) / 2);
  }

  static double _atan2Impl(double y, double x) {
    if (x > 0)
      return (y / x).atan();
    else if (x < 0 && y >= 0)
      return (y / x).atan() + 3.14159265359;
    else if (x < 0 && y < 0)
      return (y / x).atan() - 3.14159265359;
    else if (x == 0 && y > 0)
      return 3.14159265359 / 2;
    else if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
}
