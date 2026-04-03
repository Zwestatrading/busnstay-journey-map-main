import 'package:supabase_flutter/supabase_flutter.dart';

class HotelService {
  final SupabaseClient supabase;

  HotelService({required this.supabase});

  Future<List<Map<String, dynamic>>> getPendingBookings(String hotelId) async {
    try {
      final data = await supabase
          .from('bookings')
          .select()
          .eq('hotel_id', hotelId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error fetching pending bookings: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConfirmedBookings(String hotelId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final data = await supabase
          .from('bookings')
          .select()
          .eq('hotel_id', hotelId)
          .eq('status', 'confirmed')
          .gte('check_in_date', dateStr)
          .lte('check_in_date', '${dateStr}T23:59:59')
          .order('check_in_date');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error fetching confirmed bookings: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRooms(String hotelId) async {
    try {
      final data = await supabase
          .from('rooms')
          .select()
          .eq('hotel_id', hotelId)
          .order('number');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error fetching rooms: $e');
      return [];
    }
  }

  Future<double> getOccupancyRate(String hotelId) async {
    try {
      final rooms = await getRooms(hotelId);
      if (rooms.isEmpty) return 0;
      final occupied = rooms.where((r) => r['status'] == 'occupied').length;
      return (occupied / rooms.length) * 100;
    } catch (e) {
      print('❌ Error calculating occupancy: $e');
      return 0;
    }
  }

  Future<double> getTodayRevenue(String hotelId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final data = await supabase
          .from('bookings')
          .select('total_price')
          .eq('hotel_id', hotelId)
          .eq('status', 'confirmed')
          .gte('created_at', today);
      double total = 0;
      for (final row in data) {
        total += (row['total_price'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error fetching revenue: $e');
      return 0;
    }
  }

  RealtimeChannel subscribeToBookings(String hotelId) {
    return supabase.channel('hotel_bookings_$hotelId').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'hotel_id',
        value: hotelId,
      ),
      callback: (payload) {
        print('📢 Hotel booking update: ${payload.eventType}');
      },
    ).subscribe();
  }

  Future<bool> confirmBooking(String bookingId, String guestPhone) async {
    try {
      await supabase.from('bookings').update({
        'status': 'confirmed',
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      return true;
    } catch (e) {
      print('❌ Error confirming booking: $e');
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, String guestPhone, String reason) async {
    try {
      await supabase.from('bookings').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', bookingId);
      return true;
    } catch (e) {
      print('❌ Error rejecting booking: $e');
      return false;
    }
  }

  Future<bool> checkIn(String bookingId, String guestPhone) async {
    try {
      await supabase.from('bookings').update({
        'status': 'checked_in',
        'checked_in_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      return true;
    } catch (e) {
      print('❌ Error checking in: $e');
      return false;
    }
  }
}
