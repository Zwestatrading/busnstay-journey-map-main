import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerService {
  final SupabaseClient supabase;

  PassengerService({required this.supabase});

  // Book a bus trip
  Future<Map<String, dynamic>?> bookTrip({
    required String passengerId,
    required String journeyId,
    required int seats,
    required double totalPrice,
  }) async {
    try {
      final response = await supabase.from('bookings').insert({
        'passenger_id': passengerId,
        'journey_id': journeyId,
        'seats': seats,
        'total_price': totalPrice,
        'status': 'confirmed',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      print('❌ [BOOKING] Error booking trip: $e');
      return null;
    }
  }

  // Get passenger bookings
  Future<List<Map<String, dynamic>>> getBookings(String passengerId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('*, journeys(*, buses(*))')
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [BOOKINGS] Error fetching bookings: $e');
      return [];
    }
  }

  // Get available journeys
  Future<List<Map<String, dynamic>>> getAvailableJourneys({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toString().split(' ')[0];
      final response = await supabase
          .from('journeys')
          .select('*, buses(*, drivers(*))')
          .eq('origin', origin)
          .eq('destination', destination)
          .eq('journey_date', dateStr)
          .eq('status', 'active')
          .gt('available_seats', 0);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [JOURNEYS] Error fetching journeys: $e');
      return [];
    }
  }

  // Wallet transactions
  Future<List<Map<String, dynamic>>> getTransactions(String passengerId) async {
    try {
      final response = await supabase
          .from('wallet_transactions')
          .select()
          .eq('user_id', passengerId)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [TRANSACTIONS] Error fetching transactions: $e');
      return [];
    }
  }

  // Real-time trip tracking
  RealtimeChannel trackTrip(String bookingId) {
    return supabase.channel('booking:$bookingId').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'journeys',
      callback: (payload) {
        print('📍 [TRACKING] Trip updated: ${payload.newRecord}');
      },
    ).subscribe();
  }
}
