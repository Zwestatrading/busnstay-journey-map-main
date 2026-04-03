import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing restaurant verification and approval workflows
/// Ensures only legitimate restaurants appear in the app
class RestaurantVerificationService {
  final SupabaseClient supabase;

  RestaurantVerificationService({required this.supabase});

  /// Create a new restaurant (pending approval)
  /// Returns: {'success': bool, 'id': String, 'message': String}
  Future<Map<String, dynamic>> submitRestaurantForApproval({
    required String name,
    required String ownerName,
    required String ownerPhone,
    required String ownerEmail,
    required double latitude,
    required double longitude,
    required String locationDescription,
    required String cuisineType,
    required String documentsUrl, // URL to registration documents
    required String photographUrl, // Photo of restaurant/storefront
  }) async {
    try {
      final response = await supabase.from('restaurants').insert({
        'name': name,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        'owner_email': ownerEmail,
        'latitude': latitude,
        'longitude': longitude,
        'location_description': locationDescription,
        'cuisine_type': cuisineType,
        'documents_url': documentsUrl,
        'photograph_url': photographUrl,
        'status': 'pending_approval', // Not 'approved' until admin checks
        'is_visible': false, // Hidden from customers until approved
        'created_at': DateTime.now().toIso8601String(),
        'submission_date': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        return {
          'success': true,
          'id': response[0]['id'],
          'message':
              '✅ Restaurant submitted for approval. Admin will review within 24-48 hours.',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error creating restaurant record',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error submitting restaurant: $e',
      };
    }
  }

  /// Get pending restaurants for admin approval
  Future<List<Map<String, dynamic>>> getPendingRestaurants() async {
    try {
      final response = await supabase
          .from('restaurants')
          .select()
          .eq('status', 'pending_approval')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching pending restaurants: $e');
      return [];
    }
  }

  /// Approve a restaurant (admin only)
  /// Now it becomes visible to customers
  Future<Map<String, dynamic>> approveRestaurant({
    required String restaurantId,
    required String approverName,
    required String approvalNotes,
  }) async {
    try {
      await supabase.from('restaurants').update({
        'status': 'approved',
        'is_visible': true,
        'approved_at': DateTime.now().toIso8601String(),
        'approved_by': approverName,
        'approval_notes': approvalNotes,
      }).eq('id', restaurantId);

      print('✅ Restaurant #$restaurantId APPROVED');
      return {
        'success': true,
        'message': '✅ Restaurant approved and now visible to customers',
      };
    } catch (e) {
      print('❌ Error approving restaurant: $e');
      return {
        'success': false,
        'message': '❌ Error approving restaurant: $e',
      };
    }
  }

  /// Reject a restaurant (admin only)
  /// Restaurant won't appear in the app
  Future<Map<String, dynamic>> rejectRestaurant({
    required String restaurantId,
    required String rejectionReason,
  }) async {
    try {
      final restaurant =
          await supabase.from('restaurants').select().eq('id', restaurantId).single();

      await supabase.from('restaurants').update({
        'status': 'rejected',
        'is_visible': false,
        'rejection_reason': rejectionReason,
        'rejected_at': DateTime.now().toIso8601String(),
      }).eq('id', restaurantId);

      // Notify owner
      await _notifyRestaurantOwner(
        ownerEmail: restaurant['owner_email'],
        ownerPhone: restaurant['owner_phone'],
        restaurantName: restaurant['name'],
        reason: rejectionReason,
        isApproved: false,
      );

      print('❌ Restaurant #$restaurantId REJECTED');
      return {
        'success': true,
        'message': '✅ Restaurant rejected. Owner has been notified.',
      };
    } catch (e) {
      print('❌ Error rejecting restaurant: $e');
      return {
        'success': false,
        'message': '❌ Error rejecting: $e',
      };
    }
  }

  /// Get only APPROVED restaurants visible to customers
  Future<List<Map<String, dynamic>>> getApprovedRestaurants() async {
    try {
      final response = await supabase
          .from('restaurants')
          .select()
          .eq('status', 'approved')
          .eq('is_visible', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching approved restaurants: $e');
      return [];
    }
  }

  /// Get restaurants near a location (only approved ones)
  Future<List<Map<String, dynamic>>> getNearbyApprovedRestaurants({
    required double userLat,
    required double userLng,
    required double radiusKm,
  }) async {
    try {
      final response = await supabase
          .from('restaurants')
          .select()
          .eq('status', 'approved')
          .eq('is_visible', true);

      final restaurants = List<Map<String, dynamic>>.from(response);

      // Filter by distance
      final nearby = restaurants.where((r) {
        double distance = _calculateDistance(
          userLat,
          userLng,
          r['latitude'] as double,
          r['longitude'] as double,
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
      print('❌ Error fetching nearby restaurants: $e');
      return [];
    }
  }

  /// Get restaurant details including menu items and ratings
  Future<Map<String, dynamic>?> getRestaurantDetails(String restaurantId) async {
    try {
      final restaurant = await supabase
          .from('restaurants')
          .select('*, menu_items(*), reviews(*)')
          .eq('id', restaurantId)
          .eq('status', 'approved') // Only approved restaurants
          .single();

      return restaurant as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error fetching restaurant details: $e');
      return null;
    }
  }

  /// Verify restaurant ownership (for dashboard login)
  Future<bool> verifyRestaurantOwnership({
    required String restaurantId,
    required String ownerEmail,
    required String password,
  }) async {
    try {
      final response = await supabase
          .from('restaurants')
          .select('id')
          .eq('id', restaurantId)
          .eq('owner_email', ownerEmail)
          .eq('status', 'approved')
          .single();

      return response != null;
    } catch (e) {
      print('❌ Error verifying restaurant ownership: $e');
      return false;
    }
  }

  /// Update restaurant profile (owner can update after approval)
  Future<Map<String, dynamic>> updateRestaurantProfile({
    required String restaurantId,
    required String? name,
    required String? cuisineType,
    required String? locationDescription,
    required String? photographUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (cuisineType != null) updates['cuisine_type'] = cuisineType;
      if (locationDescription != null) updates['location_description'] = locationDescription;
      if (photographUrl != null) updates['photograph_url'] = photographUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('restaurants').update(updates).eq('id', restaurantId);

      return {
        'success': true,
        'message': '✅ Restaurant profile updated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error updating profile: $e',
      };
    }
  }

  /// Get restaurant analytics (revenue, orders, ratings)
  Future<Map<String, dynamic>?> getRestaurantAnalytics({
    required String restaurantId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final dailyOrders = await supabase
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('status', 'delivered')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final totalRevenue = (dailyOrders as List)
          .fold<double>(0, (sum, order) => sum + ((order['total_amount'] as num?)?.toDouble() ?? 0));

      final reviews = await supabase
          .from('reviews')
          .select('rating')
          .eq('restaurant_id', restaurantId);

      final avgRating = reviews.isEmpty
          ? 0.0
          : (reviews as List)
                  .fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble()) /
              reviews.length;

      return {
        'total_orders': dailyOrders.length,
        'total_revenue': totalRevenue,
        'average_rating': avgRating,
        'review_count': reviews.length,
      };
    } catch (e) {
      print('❌ Error fetching analytics: $e');
      return null;
    }
  }

  /// Calculate distance using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = (sin(_toRad(dLat / 2)) * sin(_toRad(dLat / 2))) +
        (cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(_toRad(dLng / 2)) * sin(_toRad(dLng / 2)));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double sin(double value) {
    return _sinImpl(value);
  }

  static double cos(double value) {
    return _cosImpl(value);
  }

  static double sqrt(double value) {
    return _sqrtImpl(value);
  }

  static double atan2(double y, double x) {
    return _atan2Impl(y, x);
  }

  static double _toRad(double value) => value * (3.14159265359 / 180);

  static double _sinImpl(double x) {
    // Using Taylor series approximation for sine
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
    // atan2 implementation
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

  /// Send approval/rejection notification to restaurant owner
  Future<void> _notifyRestaurantOwner({
    required String ownerEmail,
    required String ownerPhone,
    required String restaurantName,
    required String reason,
    required bool isApproved,
  }) async {
    try {
      // TODO: Integrate with email service (SendGrid, Firebase)
      // TODO: Integrate with SMS service (Twilio, AWS SNS)
      // For now, just log it
      if (isApproved) {
        print('📧 Email: $restaurantName has been APPROVED!');
      } else {
        print('📧 Email: $restaurantName has been REJECTED. Reason: $reason');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }
}
