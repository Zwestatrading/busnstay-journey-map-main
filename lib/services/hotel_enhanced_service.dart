import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Comprehensive hotel management service
/// Handles rooms, bookings, availability, and revenue tracking
class HotelEnhancedService {
  final SupabaseClient supabase;

  HotelEnhancedService({required this.supabase});

  Future<String?> uploadRoomImageBytes({
    required Uint8List bytes,
    required String hotelId,
    required String roomId,
    String extension = 'jpg',
  }) async {
    try {
      final fileName =
          'room_${hotelId}_${roomId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'hotels/$hotelId/$fileName';

      await supabase.storage.from('hotel_room_images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return supabase.storage.from('hotel_room_images').getPublicUrl(path);
    } catch (e) {
      print('❌ Error uploading hotel room image: $e');
      return null;
    }
  }

  // ===== ROOM MANAGEMENT =====

  /// Add new room to hotel
  /// Returns: {'success': bool, 'id': String, 'message': String}
  Future<Map<String, dynamic>> addRoom({
    required String hotelId,
    required String roomNumber,
    required String roomType, // 'single', 'double', 'suite', 'executive'
    required double price,
    required int capacity,
    required List<String> amenities,
    required List<String> imageUrls,
    required String description,
  }) async {
    try {
      final response = await supabase.from('rooms').insert({
        'hotel_id': hotelId,
        'number': roomNumber,
        'type': roomType,
        'price': price,
        'capacity': capacity,
        'amenities': amenities,
        'images': imageUrls,
        'description': description,
        'is_active': true,
        'is_available': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        return {
          'success': true,
          'id': response[0]['id'],
          'message': '✅ Room #$roomNumber added successfully',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error creating room',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error adding room: $e',
      };
    }
  }

  /// Update room details
  Future<Map<String, dynamic>> updateRoom({
    required String roomId,
    required String? roomNumber,
    required String? roomType,
    required double? price,
    required int? capacity,
    required List<String>? amenities,
    required List<String>? imageUrls,
    required String? description,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (roomNumber != null) updates['number'] = roomNumber;
      if (roomType != null) updates['type'] = roomType;
      if (price != null) updates['price'] = price;
      if (capacity != null) updates['capacity'] = capacity;
      if (amenities != null) updates['amenities'] = amenities;
      if (imageUrls != null) updates['images'] = imageUrls;
      if (description != null) updates['description'] = description;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('rooms').update(updates).eq('id', roomId);

      return {
        'success': true,
        'message': '✅ Room updated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error updating room: $e',
      };
    }
  }

  /// Delete room
  Future<Map<String, dynamic>> deleteRoom(String roomId) async {
    try {
      await supabase.from('rooms').delete().eq('id', roomId);

      return {
        'success': true,
        'message': '✅ Room deleted',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error deleting room: $e',
      };
    }
  }

  // ===== AVAILABILITY MANAGEMENT =====

  /// Toggle room availability (when fully booked, set to inactive)
  /// Returns: {'success': bool, 'is_available': bool}
  Future<Map<String, dynamic>> toggleRoomAvailability({
    required String roomId,
    required bool isAvailable,
    String? reason, // e.g., "Fully booked", "Under maintenance"
  }) async {
    try {
      final updates = <String, dynamic>{
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        updates['availability_reason'] = reason;
      }

      await supabase.from('rooms').update(updates).eq('id', roomId);

      return {
        'success': true,
        'is_available': isAvailable,
        'message': isAvailable ? '✅ Room is now available' : '❌ Room marked as unavailable',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error toggling availability: $e',
      };
    }
  }

  /// Get available rooms for date range
  Future<List<Map<String, dynamic>>> getAvailableRooms({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Get all active rooms
      final rooms = await supabase
          .from('rooms')
          .select()
          .eq('hotel_id', hotelId)
          .eq('is_active', true)
          .eq('is_available', true);

      // Filter out booked rooms for these dates
      final bookings = await supabase
          .from('bookings')
          .select('room_id')
          .eq('hotel_id', hotelId)
          .inFilter('status', ['confirmed', 'checked_in'])
          .gte('check_in_date', checkIn.toIso8601String())
          .lte('check_out_date', checkOut.toIso8601String());

      final bookedRoomIds = (bookings as List).map((b) => b['room_id']).toList();

      final available = (rooms as List)
          .where((r) => !bookedRoomIds.contains(r['id']))
          .toList();

      return List<Map<String, dynamic>>.from(available);
    } catch (e) {
      print('❌ Error fetching available rooms: $e');
      return [];
    }
  }

  // ===== BOOKING MANAGEMENT =====

  /// Create booking
  Future<Map<String, dynamic>> createBooking({
    required String hotelId,
    required String roomId,
    required String guestName,
    required String guestPhone,
    required String guestEmail,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numberOfGuests,
  }) async {
    try {
      // Get room details to calculate price
      final room = await supabase.from('rooms').select().eq('id', roomId).single();

      final nights = checkOutDate.difference(checkInDate).inDays;
      final totalPrice = (room['price'] as num) * nights;

      final response = await supabase.from('bookings').insert({
        'hotel_id': hotelId,
        'room_id': roomId,
        'guest_name': guestName,
        'guest_phone': guestPhone,
        'guest_email': guestEmail,
        'check_in_date': checkInDate.toIso8601String(),
        'check_out_date': checkOutDate.toIso8601String(),
        'number_of_guests': numberOfGuests,
        'total_price': totalPrice,
        'number_of_nights': nights,
        'status': 'pending', // Awaiting hotel confirmation
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        return {
          'success': true,
          'id': response[0]['id'],
          'total_price': totalPrice,
          'message': '✅ Booking created. Awaiting hotel confirmation.',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error creating booking',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error creating booking: $e',
      };
    }
  }

  /// Confirm booking (hotel accepts it)
  Future<bool> confirmBooking(String bookingId) async {
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

  /// Reject booking (hotel rejects it)
  Future<bool> rejectBooking(String bookingId, String reason) async {
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

  /// Check in guest
  Future<bool> checkInGuest(String bookingId) async {
    try {
      await supabase.from('bookings').update({
        'status': 'checked_in',
        'checked_in_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      print('❌ Error checking in guest: $e');
      return false;
    }
  }

  /// Check out guest
  Future<bool> checkOutGuest(String bookingId) async {
    try {
      await supabase.from('bookings').update({
        'status': 'completed',
        'checked_out_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      print('❌ Error checking out guest: $e');
      return false;
    }
  }

  /// Get bookings by status
  Future<List<Map<String, dynamic>>> getBookingsByStatus({
    required String hotelId,
    required String status,
  }) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('*, rooms(*)')
          .eq('hotel_id', hotelId)
          .eq('status', status)
          .order('check_in_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      return [];
    }
  }

  // ===== ANALYTICS & REPORTING =====

  /// Get occupancy rate for a specific date
  Future<Map<String, dynamic>> getOccupancyAnalytics({
    required String hotelId,
    required DateTime date,
  }) async {
    try {
      // Get total rooms
      final totalRooms =
          await supabase.from('rooms').select().eq('hotel_id', hotelId).eq('is_active', true);

      // Get occupied rooms for this date
      final occupied = await supabase.from('bookings').select().eq('hotel_id', hotelId).inFilter(
          'status', ['confirmed', 'checked_in']).gte('check_in_date',
              date.toIso8601String()).lte('check_out_date', date.toIso8601String());

      final total = (totalRooms as List).length;
      final occupiedCount = (occupied as List).length;
      final rate = total > 0 ? (occupiedCount / total * 100).toStringAsFixed(1) : '0';

      return {
        'total_rooms': total,
        'occupied_rooms': occupiedCount,
        'occupancy_rate': '$rate%',
        'available_rooms': total - occupiedCount,
      };
    } catch (e) {
      print('❌ Error calculating occupancy: $e');
      return {
        'occupancy_rate': '0%',
      };
    }
  }

  /// Get revenue report
  Future<Map<String, dynamic>> getRevenueReport({
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final bookings = await supabase
          .from('bookings')
          .select()
          .eq('hotel_id', hotelId)
          .inFilter('status', ['confirmed', 'checked_in', 'completed'])
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalRevenue = 0;
      int totalBookings = 0;

      for (final booking in bookings as List) {
        totalRevenue += (booking['total_price'] as num?)?.toDouble() ?? 0;
        totalBookings++;
      }

      final avgRevenuePerBooking = totalBookings > 0 ? totalRevenue / totalBookings : 0;

      return {
        'total_revenue': totalRevenue.toStringAsFixed(2),
        'total_bookings': totalBookings,
        'average_per_booking': avgRevenuePerBooking.toStringAsFixed(2),
        'period': '${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}',
      };
    } catch (e) {
      print('❌ Error calculating revenue: $e');
      return {
        'total_revenue': '0',
        'total_bookings': 0,
      };
    }
  }

  /// Get rooms by type with availability
  Future<List<Map<String, dynamic>>> getRoomsByType({
    required String hotelId,
    required String roomType,
  }) async {
    try {
      final response = await supabase
          .from('rooms')
          .select()
          .eq('hotel_id', hotelId)
          .eq('type', roomType)
          .eq('is_active', true)
          .order('price');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching rooms by type: $e');
      return [];
    }
  }

  /// Get hotel statistics dashboard
  Future<Map<String, dynamic>> getHotelDashboard(String hotelId) async {
    try {
      final rooms = await supabase.from('rooms').select().eq('hotel_id', hotelId).eq('is_active', true);

      final todayBookings = await supabase
          .from('bookings')
          .select()
          .eq('hotel_id', hotelId)
          .eq('status', 'confirmed')
          .gte('check_in_date', DateTime.now().toIso8601String().split('T')[0]);

      final totalRevenue = await supabase
          .from('bookings')
          .select('total_price')
          .eq('hotel_id', hotelId)
          .eq('status', 'completed');

      double revenue = 0;
      for (final booking in totalRevenue as List) {
        revenue += (booking['total_price'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_rooms': (rooms as List).length,
        'today_bookings': (todayBookings as List).length,
        'total_revenue': revenue.toStringAsFixed(2),
        'rooms_available': (rooms as List).where((r) => r['is_available'] == true).length,
      };
    } catch (e) {
      print('❌ Error fetching dashboard: $e');
      return {
        'total_rooms': 0,
        'today_bookings': 0,
        'total_revenue': '0',
      };
    }
  }

  /// Real-time booking updates
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
        print('📢 Booking update: ${payload.eventType}');
      },
    ).subscribe();
  }
}
