import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service to fetch real road geometry from Google Directions API
/// This provides accurate routing that follows actual road networks
class DirectionsService {
  // Get this from: https://console.cloud.google.com
  // Must enable Directions API and Maps SDK for Flutter
  final String googleMapsApiKey;

  DirectionsService({required this.googleMapsApiKey});

  /// Fetch route from start to end using Google Directions API
  /// Returns: {
  ///   'success': bool,
  ///   'polyline_points': List<LatLng>,
  ///   'distance_meters': double,
  ///   'duration_seconds': int,
  ///   'steps': List<Map> - turn-by-turn directions,
  ///   'error': String?
  /// }
  Future<Map<String, dynamic>> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String mode, // 'driving', 'transit', etc.
  }) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$startLat,$startLng'
          '&destination=$endLat,$endLng'
          '&mode=$mode'
          '&key=$googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final leg = route['legs'][0];

          // Decode polyline to get actual route points
          final polylinePoints = _decodePolyline(
            route['overview_polyline']['points'],
          );

          // Extract steps for turn-by-turn directions
          final steps = leg['steps'] as List?;
          final directionsSteps = steps?.map((step) {
            return {
              'instruction': step['html_instructions'].toString(),
              'distance_meters': step['distance']['value'],
              'duration_seconds': step['duration']['value'],
              'start_location': {
                'lat': step['start_location']['lat'],
                'lng': step['start_location']['lng'],
              },
              'end_location': {
                'lat': step['end_location']['lat'],
                'lng': step['end_location']['lng'],
              },
            };
          }).toList();

          return {
            'success': true,
            'polyline_points': polylinePoints,
            'distance_meters': leg['distance']['value'],
            'distance_km': (leg['distance']['value'] as num) / 1000,
            'duration_seconds': leg['duration']['value'],
            'duration_text': leg['duration']['text'],
            'steps': directionsSteps ?? [],
            'start_address': leg['start_address'],
            'end_address': leg['end_address'],
          };
        } else {
          return {
            'success': false,
            'polyline_points': [],
            'error': 'No routes found: ${json['status']}',
          };
        }
      } else {
        return {
          'success': false,
          'polyline_points': [],
          'error': 'API Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'polyline_points': [],
        'error': 'Error fetching directions: $e',
      };
    }
  }

  /// Fetch multiple routes with alternatives
  /// Useful for showing multiple route options
  Future<Map<String, dynamic>> getAlternativeRoutes({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$startLat,$startLng'
          '&destination=$endLat,$endLng'
          '&mode=driving'
          '&alternatives=true'
          '&key=$googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final routes = (json['routes'] as List).map((route) {
            final leg = route['legs'][0];
            return {
              'polyline_points': _decodePolyline(
                route['overview_polyline']['points'],
              ),
              'distance_km': (leg['distance']['value'] as num) / 1000,
              'duration_text': leg['duration']['text'],
              'summary': route['summary'] ?? 'Route',
            };
          }).toList();

          return {'success': true, 'routes': routes};
        } else {
          return {'success': false, 'routes': [], 'error': json['status']};
        }
      } else {
        return {
          'success': false,
          'routes': [],
          'error': 'API Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'routes': [], 'error': 'Error: $e'};
    }
  }

  /// Decode polyline points from Google Directions API
  /// Google returns encoded polyline strings; this decodes them
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      poly.add(LatLng(latitude, longitude));
    }
    return poly;
  }

  /// Check if a point is close to the route (within tolerance)
  /// Returns: {'on_route': bool, 'closest_point': LatLng, 'distance_km': double}
  Map<String, dynamic> isPointOnRoute({
    required double lat,
    required double lng,
    required List<LatLng> routePoints,
    double toleranceKm = 3.0,
  }) {
    double minDistance = double.infinity;
    LatLng closestPoint = routePoints.first;

    for (final point in routePoints) {
      final distance = _calculateDistance(
        lat,
        lng,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    return {
      'on_route': minDistance <= toleranceKm,
      'closest_point': closestPoint,
      'distance_km': minDistance,
    };
  }

  /// Haversine formula to calculate distance between two coordinates
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double value) => value * (3.14159265359 / 180);
}
