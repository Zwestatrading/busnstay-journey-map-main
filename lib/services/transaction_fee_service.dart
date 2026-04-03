import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing transaction fees and revenue distribution
/// Calculate fees from restaurant orders and distribute earnings
class TransactionFeeService {
  final SupabaseClient supabase;

  // Fee structure (in percentage)
  static const double PLATFORM_FEE_PERCENT = 5.0; // Platform commission
  static const double STATION_FEE_PERCENT = 2.0; // Bus station profit share
  static const double DELIVERY_FEE_PERCENT = 3.0; // Delivery partner cut

  TransactionFeeService({required this.supabase});

  // ===== FEE CALCULATION =====

  /// Calculate all fees for a restaurant order
  /// Returns breakdown of who gets what money
  static Map<String, dynamic> calculateOrderFees({
    required double orderAmount,
    required bool hasItemsFromStation,
    required bool requiresDelivery,
  }) {
    // Calculate each fee component
    final platformFee = orderAmount * (PLATFORM_FEE_PERCENT / 100);
    final stationFee = hasItemsFromStation ? orderAmount * (STATION_FEE_PERCENT / 100) : 0.0;
    final deliveryFee = requiresDelivery ? orderAmount * (DELIVERY_FEE_PERCENT / 100) : 0.0;

    final totalFees = platformFee + stationFee + deliveryFee;
    final restaurantPayout = orderAmount - totalFees;

    return {
      'order_amount': orderAmount,
      'platform_fee': platformFee,
      'station_fee': stationFee,
      'delivery_fee': deliveryFee,
      'total_fees': totalFees,
      'restaurant_payout': restaurantPayout,
      'fee_percentage': (totalFees / orderAmount * 100).toStringAsFixed(1),
    };
  }

  /// Get fee breakdown percentage
  static Map<String, String> getFeeBreakdownPercentage() {
    return {
      'platform': '$PLATFORM_FEE_PERCENT%',
      'station': '$STATION_FEE_PERCENT%',
      'delivery': '$DELIVERY_FEE_PERCENT%',
      'total': '${PLATFORM_FEE_PERCENT + STATION_FEE_PERCENT + DELIVERY_FEE_PERCENT}%',
    };
  }

  // ===== RESTAURANT REVENUE =====

  /// Get restaurant's daily revenue (after fees)
  Future<Map<String, dynamic>> getRestaurantDailyRevenue({
    required String restaurantId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Get all completed orders for this day
      final orders = await supabase
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('status', 'delivered')
          .gte('delivered_at', '${dateStr}T00:00:00')
          .lte('delivered_at', '${dateStr}T23:59:59');

      double totalOrderAmount = 0;
      double totalPlatformFees = 0;
      double totalRestaurantPayout = 0;
      int orderCount = 0;

      for (var order in orders as List) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        totalOrderAmount += amount;
        orderCount++;

        final fees = calculateOrderFees(
          orderAmount: amount,
          hasItemsFromStation: order['has_items_from_station'] ?? false,
          requiresDelivery: order['requires_delivery'] ?? true,
        );

        totalPlatformFees += (fees['platform_fee'] as num)?.toDouble() ?? 0;
        totalRestaurantPayout += (fees['restaurant_payout'] as num)?.toDouble() ?? 0;
      }

      return {
        'date': dateStr,
        'order_count': orderCount,
        'total_order_amount': totalOrderAmount.toStringAsFixed(2),
        'total_platform_fees': totalPlatformFees.toStringAsFixed(2),
        'restaurant_payout': totalRestaurantPayout.toStringAsFixed(2),
        'average_per_order': orderCount > 0
            ? (totalOrderAmount / orderCount).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      print('❌ Error calculating daily revenue: $e');
      return {
        'order_count': 0,
        'restaurant_payout': '0.00',
      };
    }
  }

  /// Get restaurant's monthly revenue
  Future<Map<String, dynamic>> getRestaurantMonthlyRevenue({
    required String restaurantId,
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1).subtract(Duration(days: 1));

      final orders = await supabase
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('status', 'delivered')
          .gte('delivered_at', startDate.toIso8601String())
          .lte('delivered_at', endDate.toIso8601String());

      double totalOrderAmount = 0;
      double totalRestaurantPayout = 0;
      int orderCount = 0;

      for (var order in orders as List) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        totalOrderAmount += amount;
        orderCount++;

        final fees = calculateOrderFees(
          orderAmount: amount,
          hasItemsFromStation: order['has_items_from_station'] ?? false,
          requiresDelivery: order['requires_delivery'] ?? true,
        );

        totalRestaurantPayout += (fees['restaurant_payout'] as num)?.toDouble() ?? 0;
      }

      // Calculate daily average
      final dayCount = endDate.difference(startDate).inDays + 1;
      final avgPerDay = orderCount > 0 ? totalOrderAmount / dayCount : 0;

      return {
        'month': '$month/$year',
        'order_count': orderCount,
        'total_order_amount': totalOrderAmount.toStringAsFixed(2),
        'restaurant_payout': totalRestaurantPayout.toStringAsFixed(2),
        'average_per_day': avgPerDay.toStringAsFixed(2),
        'average_per_order': orderCount > 0
            ? (totalOrderAmount / orderCount).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      print('❌ Error calculating monthly revenue: $e');
      return {
        'order_count': 0,
        'restaurant_payout': '0.00',
      };
    }
  }

  /// Get restaurant's total earnings (all time)
  Future<Map<String, dynamic>> getRestaurantTotalEarnings(String restaurantId) async {
    try {
      final allOrders = await supabase
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('status', 'delivered');

      double totalOrderAmount = 0;
      double totalRestaurantPayout = 0;
      int orderCount = 0;

      for (var order in allOrders as List) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        totalOrderAmount += amount;
        orderCount++;

        final fees = calculateOrderFees(
          orderAmount: amount,
          hasItemsFromStation: order['has_items_from_station'] ?? false,
          requiresDelivery: order['requires_delivery'] ?? true,
        );

        totalRestaurantPayout += (fees['restaurant_payout'] as num)?.toDouble() ?? 0;
      }

      return {
        'total_orders': orderCount,
        'total_order_amount': totalOrderAmount.toStringAsFixed(2),
        'total_restaurant_payout': totalRestaurantPayout.toStringAsFixed(2),
        'average_per_order': orderCount > 0
            ? (totalOrderAmount / orderCount).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      print('❌ Error calculating total earnings: $e');
      return {
        'total_orders': 0,
        'total_restaurant_payout': '0.00',
      };
    }
  }

  // ===== PAYOUT MANAGEMENT =====

  /// Request payout for restaurant
  /// Transfers money to restaurant owner's account
  Future<Map<String, dynamic>> requestRestaurantPayout({
    required String restaurantId,
    required double amount,
    required String bankAccount,
  }) async {
    try {
      // Check if restaurant has enough balance
      final earnings = await getRestaurantTotalEarnings(restaurantId);
      final availableBalance =
          double.parse(earnings['total_restaurant_payout'] as String? ?? '0');

      if (amount > availableBalance) {
        return {
          'success': false,
          'message': 'Insufficient balance. Available: K${availableBalance.toStringAsFixed(2)}',
        };
      }

      // Create payout request
      final response = await supabase.from('restaurant_payouts').insert({
        'restaurant_id': restaurantId,
        'amount': amount,
        'bank_account': bankAccount,
        'status': 'pending', // Awaiting admin approval
        'requested_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        return {
          'success': true,
          'id': response[0]['id'],
          'message':
              '✅ Payout request submitted. Admin will process within 2-5 business days.',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error creating payout request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error: $e',
      };
    }
  }

  /// Approve payout (admin only)
  Future<bool> approvePayout(String payoutId) async {
    try {
      await supabase.from('restaurant_payouts').update({
        'status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', payoutId);

      return true;
    } catch (e) {
      print('❌ Error approving payout: $e');
      return false;
    }
  }

  /// Complete payout (funds transferred)
  Future<bool> completePayout(String payoutId) async {
    try {
      await supabase.from('restaurant_payouts').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', payoutId);

      return true;
    } catch (e) {
      print('❌ Error completing payout: $e');
      return false;
    }
  }

  /// Get payout history for a restaurant
  Future<List<Map<String, dynamic>>> getPayoutHistory(String restaurantId) async {
    try {
      final response = await supabase
          .from('restaurant_payouts')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching payout history: $e');
      return [];
    }
  }

  // ===== STATION REVENUE =====

  /// Get station's revenue from transaction fees
  /// Station gets a cut from orders at restaurants in their station
  Future<Map<String, dynamic>> getStationRevenue({
    required String stationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all orders from services in this station
      final orders = await supabase
          .from('orders')
          .select()
          .eq('station_id', stationId)
          .eq('status', 'delivered')
          .gte('delivered_at', startDate.toIso8601String())
          .lte('delivered_at', endDate.toIso8601String());

      double totalStationFees = 0;
      int orderCount = 0;

      for (var order in orders as List) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        orderCount++;

        final fees = calculateOrderFees(
          orderAmount: amount,
          hasItemsFromStation: true,
          requiresDelivery: false,
        );

        totalStationFees += (fees['station_fee'] as num?)?.toDouble() ?? 0;
      }

      return {
        'period':
            '${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}',
        'order_count': orderCount,
        'total_station_revenue': totalStationFees.toStringAsFixed(2),
        'average_per_order': orderCount > 0
            ? (totalStationFees / orderCount).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      print('❌ Error fetching station revenue: $e');
      return {
        'order_count': 0,
        'total_station_revenue': '0.00',
      };
    }
  }

  // ===== FINANCIAL REPORTS =====

  /// Get platform financial summary
  Future<Map<String, dynamic>> getPlatformFinancials({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all completed orders in period
      final orders = await supabase
          .from('orders')
          .select()
          .eq('status', 'delivered')
          .gte('delivered_at', startDate.toIso8601String())
          .lte('delivered_at', endDate.toIso8601String());

      double totalOrderAmount = 0;
      double totalPlatformFees = 0;
      double totalRestaurantPayouts = 0;
      int orderCount = 0;

      for (var order in orders as List) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        totalOrderAmount += amount;
        orderCount++;

        final fees = calculateOrderFees(
          orderAmount: amount,
          hasItemsFromStation: order['has_items_from_station'] ?? false,
          requiresDelivery: order['requires_delivery'] ?? true,
        );

        totalPlatformFees += (fees['platform_fee'] as num?)?.toDouble() ?? 0;
        totalRestaurantPayouts += (fees['restaurant_payout'] as num?)?.toDouble() ?? 0;
      }

      return {
        'period':
            '${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}',
        'total_orders': orderCount,
        'total_order_amount': totalOrderAmount.toStringAsFixed(2),
        'total_platform_revenue': totalPlatformFees.toStringAsFixed(2),
        'total_restaurant_payouts': totalRestaurantPayouts.toStringAsFixed(2),
        'net_platform_profit': (totalPlatformFees - totalRestaurantPayouts).toStringAsFixed(2),
      };
    } catch (e) {
      print('❌ Error fetching platform financials: $e');
      return {
        'total_orders': 0,
      };
    }
  }

  // ===== TRANSACTION AUDIT =====

  /// Log a transaction for audit trail
  Future<bool> logTransaction({
    required String restaurantId,
    required String orderId,
    required double orderAmount,
    required double platformFee,
    required double stationFee,
    required double deliveryFee,
    required double restaurantPayout,
  }) async {
    try {
      await supabase.from('transaction_audit_log').insert({
        'restaurant_id': restaurantId,
        'order_id': orderId,
        'order_amount': orderAmount,
        'platform_fee': platformFee,
        'station_fee': stationFee,
        'delivery_fee': deliveryFee,
        'restaurant_payout': restaurantPayout,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ Error logging transaction: $e');
      return false;
    }
  }

  /// Export transaction report for accounting
  Future<List<Map<String, dynamic>>> exportTransactionReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase
          .from('transaction_audit_log')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error exporting report: $e');
      return [];
    }
  }
}
