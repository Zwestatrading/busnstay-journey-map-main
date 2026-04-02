import 'package:supabase_flutter/supabase_flutter.dart';

class BusOperatorService {
  final SupabaseClient supabase;

  BusOperatorService({required this.supabase});

  // Get operator's buses
  Future<List<Map<String, dynamic>>> getBuses(String operatorId) async {
    try {
      final response = await supabase
          .from('buses')
          .select('*, drivers(*)')
          .eq('operator_id', operatorId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [BUSES] Error fetching buses: $e');
      return [];
    }
  }

  // Get operator's active journeys
  Future<List<Map<String, dynamic>>> getActiveJourneys(String operatorId) async {
    try {
      final response = await supabase
          .from('journeys')
          .select('*, buses(*), bookings(count)')
          .eq('operator_id', operatorId)
          .inFilter('status', ['scheduled', 'active'])
          .gte('journey_date', DateTime.now().toIso8601String());

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [JOURNEYS] Error fetching journeys: $e');
      return [];
    }
  }

  // Create new journey
  Future<Map<String, dynamic>?> createJourney({
    required String operatorId,
    required String busId,
    required String origin,
    required String destination,
    required DateTime journeyDate,
    required double price,
    required int totalSeats,
  }) async {
    try {
      final response = await supabase.from('journeys').insert({
        'operator_id': operatorId,
        'bus_id': busId,
        'origin': origin,
        'destination': destination,
        'journey_date': journeyDate.toIso8601String(),
        'price': price,
        'total_seats': totalSeats,
        'available_seats': totalSeats,
        'status': 'scheduled',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        print('✅ [JOURNEY] New journey created: ${response.first['id']}');
        return response.first;
      }
      return null;
    } catch (e) {
      print('❌ [JOURNEY] Error creating journey: $e');
      return null;
    }
  }

  // Update journey status
  Future<bool> updateJourneyStatus(String journeyId, String status) async {
    try {
      await supabase
          .from('journeys')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', journeyId);

      print('✅ [JOURNEY] Journey #$journeyId status updated to: $status');
      return true;
    } catch (e) {
      print('❌ [JOURNEY] Error updating journey: $e');
      return false;
    }
  }

  // Get seat chart for journey
  Future<List<Map<String, dynamic>>> getSeatChart(String journeyId) async {
    try {
      final response = await supabase
          .from('journey_seats')
          .select('*, bookings(*)')
          .eq('journey_id', journeyId)
          .order('seat_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [SEATS] Error fetching seat chart: $e');
      return [];
    }
  }

  // Get journey revenue
  Future<double> getJourneyRevenue(String journeyId) async {
    try {
      final bookings = await supabase
          .from('bookings')
          .select('total_price')
          .eq('journey_id', journeyId)
          .eq('status', 'confirmed');

      double total = 0;
      for (var booking in bookings) {
        total += (booking['total_price'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ [REVENUE] Error fetching revenue: $e');
      return 0;
    }
  }

  // Get operator revenue for date
  Future<double> getOperatorRevenue(String operatorId, DateTime date) async {
    try {
      final dateStr = date.toString().split(' ')[0];
      final journeys = await supabase
          .from('journeys')
          .select('id')
          .eq('operator_id', operatorId)
          .eq('journey_date', dateStr);

      double total = 0;
      for (var journey in journeys) {
        total += await getJourneyRevenue(journey['id']);
      }
      return total;
    } catch (e) {
      print('❌ [REVENUE] Error fetching operator revenue: $e');
      return 0;
    }
  }

  // Real-time journey updates
  RealtimeChannel subscribeToJourney(String journeyId) {
    return supabase
        .channel('journey:$journeyId')
        .onPostgresChange(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'journeys',
          filter: 'id=eq.$journeyId',
          callback: (payload) {
            print('📊 [JOURNEY UPDATE] ${payload.newRecord}');
          },
        )
        .subscribe();
  }

  // Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      final result = await supabase.from('buses').select('id').limit(1);
      print('✅ [BUS OP] Supabase connection successful');
      return true;
    } catch (e) {
      print('❌ [BUS OP] Connection failed: $e');
      return false;
    }
  }
}
