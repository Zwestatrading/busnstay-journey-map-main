import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class MapsService {
  // Generate your Google Maps API key at: https://console.cloud.google.com
  static const String googleMapsKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Request location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }

  // Get user location stream for real-time tracking
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Calculate distance between two points using Geolocator
  static double getDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Returns km
  }

  // Create markers for delivery/journey
  static Set<Marker> createMarkers({
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> deliveryLocation,
    required String pickupLabel,
    required String deliveryLabel,
  }) {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          pickupLocation['latitude'] as double,
          pickupLocation['longitude'] as double,
        ),
        infoWindow: InfoWindow(title: pickupLabel),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          deliveryLocation['latitude'] as double,
          deliveryLocation['longitude'] as double,
        ),
        infoWindow: InfoWindow(title: deliveryLabel),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  // Create polyline for journey route
  static Set<Polyline> createPolylines({
    required List<LatLng> routePoints,
  }) {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color.fromARGB(255, 59, 130, 246), // Blue #3B82F6
        width: 5,
      ),
    };
  }

  // Create circles for geofencing (delivery radius)
  static Set<Circle> createGeofences({
    required Map<String, dynamic> location,
    required double radiusMeters,
    required String name,
  }) {
    return {
      Circle(
        circleId: CircleId(name),
        center: LatLng(
          location['latitude'] as double,
          location['longitude'] as double,
        ),
        radius: radiusMeters,
        fillColor: const Color.fromARGB(50, 59, 130, 246),
        strokeColor: const Color.fromARGB(200, 59, 130, 246),
        strokeWidth: 2,
      ),
    };
  }

  // Demo locations in Lusaka, Zambia
  static Map<String, dynamic> getDemoLocation(String name) {
    const locations = {
      'lusaka_city': {
        'latitude': -15.3875,
        'longitude': 28.3228,
        'name': 'Lusaka City Center',
        'description': 'Downtown Lusaka'
      },
      'airport': {
        'latitude': -15.2833,
        'longitude': 28.6167,
        'name': 'Harry Mwabu Airport',
        'description': 'International Airport'
      },
      'ridgeway': {
        'latitude': -15.4167,
        'longitude': 28.2833,
        'name': 'Ridgeway',
        'description': 'Ridgeway Shopping Center'
      },
      'livingstone': {
        'latitude': -17.8252,
        'longitude': 25.8711,
        'name': 'Livingstone',
        'description': 'Victoria Falls City'
      },
      'ndola': {
        'latitude': -12.9626,
        'longitude': 28.6391,
        'name': 'Ndola',
        'description': 'Copperbelt City'
      },
      'kitwe': {
        'latitude': -12.8085,
        'longitude': 28.2469,
        'name': 'Kitwe',
        'description': 'Mining City'
      },
      'cairo_road': {
        'latitude': -15.3900,
        'longitude': 28.3215,
        'name': 'Cairo Road',
        'description': 'Main Commercial Street'
      },
    };

    return locations[name.toLowerCase()] ?? locations['lusaka_city']!;
  }

  // Check if delivery is nearby (within specified meters)
  static bool isNearby(Position current, double targetLat, double targetLon, {double thresholdMeters = 100}) {
    final distanceMeters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      targetLat,
      targetLon,
    );
    return distanceMeters < thresholdMeters;
  }

  // Format location for display
  static String formatLocation({required double latitude, required double longitude}) {
    return '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°';
  }

  // Get map bounds from a list of locations
  static CameraUpdate getBoundsFromLocations(List<LatLng> locations) {
    if (locations.isEmpty) {
      // Default to Lusaka
      return CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: const LatLng(-15.4500, 28.2500),
          northeast: const LatLng(-15.3500, 28.4000),
        ),
        100,
      );
    }

    double minLat = locations[0].latitude;
    double maxLat = locations[0].latitude;
    double minLng = locations[0].longitude;
    double maxLng = locations[0].longitude;

    for (var location in locations) {
      minLat = minLat > location.latitude ? location.latitude : minLat;
      maxLat = maxLat < location.latitude ? location.latitude : maxLat;
      minLng = minLng > location.longitude ? location.longitude : minLng;
      maxLng = maxLng < location.longitude ? location.longitude : maxLng;
    }

    return CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      150,
    );
  }
}
