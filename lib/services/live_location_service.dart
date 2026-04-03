import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

/// Service for managing live location tracking for buses, deliveries, and hotels
class LiveLocationService {
  final SupabaseClient supabase;
  
  // Location listeners
  late Stream<Position>? _positionStream;
  bool _isTracking = false;

  LiveLocationService({required this.supabase});

  /// Start tracking user location
  Future<Position?> startTracking() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        Geolocator.openLocationSettings();
        return null;
      }

      _isTracking = true;

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      print('📍 Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Get continuous location stream
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Update user location in real-time (for bus driver, delivery agent, hotel manager)
  Future<void> updateLiveLocation({
    required String userId,
    required String userType, // 'bus_driver', 'delivery_agent', 'hotel_manager'
    required double latitude,
    required double longitude,
  }) async {
    try {
      await supabase.from('user_locations').upsert({
        'user_id': userId,
        'user_type': userType,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Location updated: $latitude, $longitude');
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }

  /// Get real-time tracking data for a specific journey/delivery/booking
  Stream<Map<String, dynamic>> getTracking({
    required String trackingId,
    required String trackingType, // 'journey', 'delivery', 'check_in'
  }) {
    return supabase
        .from('live_tracking')
        .stream(primaryKey: ['id'])
        .eq('tracking_id', trackingId)
        .map((data) {
          final filtered = data.where((d) => d['tracking_type'] == trackingType).toList();
          return filtered.isNotEmpty ? filtered.first : <String, dynamic>{};
        });
  }

  /// Get nearby resources (buses, hotels, delivery agents)
  Future<List<Map<String, dynamic>>> getNearbyResources({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    required String resourceType, // 'buses', 'hotels', 'restaurants'
  }) async {
    try {
      final response = await supabase.rpc('get_nearby_resources', params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_km': radiusInKm,
        'resource_type': resourceType,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('❌ Error fetching nearby resources: $e');
      return [];
    }
  }

  /// Stop tracking
  void stopTracking() {
    _isTracking = false;
    _positionStream = null;
  }
}

/// Model for location pin with marker info
class LocationPin {
  final String id;
  final String name;
  final LatLng location;
  final String type; // 'bus', 'hotel', 'restaurant', 'delivery'
  final String status; // 'available', 'busy', 'offline'
  final double rating;
  final String? imageUrl;
  final int capacity;

  LocationPin({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.status,
    required this.rating,
    this.imageUrl,
    required this.capacity,
  });

  factory LocationPin.fromJson(Map<String, dynamic> json) {
    return LocationPin(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      location: LatLng(
        json['latitude'] as double? ?? 0.0,
        json['longitude'] as double? ?? 0.0,
      ),
      type: json['type'] ?? 'unknown',
      status: json['status'] ?? 'offline',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      capacity: json['capacity'] as int? ?? 0,
    );
  }
}

/// Generate markers for Google Maps
BitmapDescriptor getMarkerIcon(String type, String status) {
  double hue;

  switch (type) {
    case 'bus':
      hue = status == 'available' ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRose;
      break;
    case 'hotel':
      hue = status == 'available' ? BitmapDescriptor.hueCyan : BitmapDescriptor.hueRose;
      break;
    case 'delivery':
      hue = status == 'active' ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueRose;
      break;
    case 'restaurant':
      hue = status == 'open' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRose;
      break;
    default:
      hue = BitmapDescriptor.hueRed;
  }

  return BitmapDescriptor.defaultMarkerWithHue(hue);
}

/// Distance calculation (Haversine formula)
double calculateDistance(LatLng from, LatLng to) {
  const earthRadius = 6371; // Radius of the earth in km

  final dLat = _toRad(to.latitude - from.latitude);
  final dLon = _toRad(to.longitude - from.longitude);

  final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      (math.cos(_toRad(from.latitude)) *
          math.cos(_toRad(to.latitude)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2));

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final distance = earthRadius * c;

  return distance;
}

double _toRad(double degree) {
  return degree * math.pi / 180;
}

