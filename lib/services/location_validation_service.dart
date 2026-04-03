import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Service for validating user location against journey routes
/// Prevents users from starting journeys outside their actual route
class LocationValidationService {
  static const double TOLERABLE_DISTANCE_KM = 5.0; // 5km radius tolerance
  static const double POINT_ON_ROUTE_TOLERANCE_KM = 3.0; // 3km to be considered on route

  /// Check if user's current location is valid for starting a journey
  /// Returns: {'valid': bool, 'message': String, 'distance_from_route': double}
  static Future<Map<String, dynamic>> validateJourneyLocation({
    required Position userLocation,
    required List<Map<String, double>> routePoints, // [{lat, lng}, ...]
    required String startTown,
    required String endTown,
  }) async {
    try {
      if (routePoints.isEmpty) {
        return {
          'valid': false,
          'message': 'Route not found. Cannot validate location.',
          'distance_from_route': 0.0,
        };
      }

      // Calculate minimum distance from user to any point on the route
      double minDistance = double.infinity;
      for (var point in routePoints) {
        double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          point['lat']!,
          point['lng']!,
        ) / 1000; // Convert to km

        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      // Check if user is within tolerance of the route
      if (minDistance <= POINT_ON_ROUTE_TOLERANCE_KM) {
        return {
          'valid': true,
          'message':
              '✅ You are on the $startTown → $endTown route. Journey can start.',
          'distance_from_route': minDistance,
        };
      } else {
        return {
          'valid': false,
          'message':
              '❌ You are ${minDistance.toStringAsFixed(1)}km away from the $startTown → $endTown route. '
              'Move closer to the route to start your journey.',
          'distance_from_route': minDistance,
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'message': '❌ Error validating location: $e',
        'distance_from_route': 0.0,
      };
    }
  }

  /// Calculate distance from user to start point (pickup)
  /// Returns distance in kilometers
  static double calculateDistanceToStart({
    required Position userLocation,
    required double startLat,
    required double startLng,
  }) {
    return Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      startLat,
      startLng,
    ) / 1000;
  }

  /// Check if user is near the start point (pickup location)
  /// Returns: {'near_start': bool, 'distance_km': double}
  static Map<String, dynamic> isNearStartPoint({
    required Position userLocation,
    required double startLat,
    required double startLng,
  }) {
    double distance = calculateDistanceToStart(
      userLocation: userLocation,
      startLat: startLat,
      startLng: startLng,
    );

    return {
      'near_start': distance <= TOLERABLE_DISTANCE_KM,
      'distance_km': distance,
      'message': distance <= TOLERABLE_DISTANCE_KM
          ? '✅ You are near the pickup location'
          : '⚠️ You are ${distance.toStringAsFixed(1)}km from pickup location',
    };
  }

  /// Calculate point on line - check if a point lies close to a line segment
  /// This is more accurate for checking if user is on the actual route
  static double distanceFromPointToLineSegment({
    required double userLat,
    required double userLng,
    required double point1Lat,
    required double point1Lng,
    required double point2Lat,
    required double point2Lng,
  }) {
    // Using Haversine formula to find perpendicular distance
    // to a line segment on the Earth's surface

    double lat1 = _radiansFromDegrees(point1Lat);
    double lon1 = _radiansFromDegrees(point1Lng);
    double lat2 = _radiansFromDegrees(point2Lat);
    double lon2 = _radiansFromDegrees(point2Lng);
    double latUser = _radiansFromDegrees(userLat);
    double lonUser = _radiansFromDegrees(userLng);

    double R = 6371; // Earth's radius in km

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double brng = math.atan2(y, x);

    double dist13 = 2 *
        math.asin(math.sqrt(math.pow(math.sin((lat1 - latUser) / 2), 2) +
            math.cos(lat1) *
                math.cos(latUser) *
                math.pow(math.sin((lon1 - lonUser) / 2), 2)));

    double dXs = math.asin(math.sin(dist13 / R) * math.sin(brng - lat1));
    double distToLine = R * math.asin(math.sqrt(math.pow(math.sin((latUser - lat1) / 2), 2) +
        math.cos(lat1) *
            math.cos(latUser) *
            math.pow(math.sin(dXs / 2), 2)));

    return distToLine.abs();
  }

  static double _radiansFromDegrees(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Validate multiple locations (for monitoring journey)
  static List<Map<String, dynamic>> validateMultipleLocations({
    required List<Position> locations,
    required List<Map<String, double>> routePoints,
  }) {
    return locations
        .map((location) {
          double minDistance = double.infinity;
          for (var point in routePoints) {
            double distance = Geolocator.distanceBetween(
              location.latitude,
              location.longitude,
              point['lat']!,
              point['lng']!,
            ) / 1000;

            if (distance < minDistance) {
              minDistance = distance;
            }
          }

          return {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'distance_from_route': minDistance,
            'is_on_route': minDistance <= POINT_ON_ROUTE_TOLERANCE_KM,
            'timestamp': location.timestamp,
          };
        })
        .toList();
  }
}
