import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to fetch real road geometry from OpenStreetMap (OSRM)
/// Uses Open Source Routing Machine - FREE alternative to Google Directions API
/// Perfect for Zambia routing without API costs
class OpenStreetMapRoutingService {
  // OSRM Demo Server (free public API)
  // For production, deploy your own OSRM instance
  static const String OSRM_BASE_URL = 'http://router.project-osrm.org'; // Free demo
  // Alternative production instance for better performance:
  // static const String OSRM_BASE_URL = 'https://your-osrm-server.com';

  /// Fetch route from start to end using OpenStreetMap/OSRM
  /// Returns: {
  ///   'success': bool,
  ///   'polyline_points': List<LatLng>,
  ///   'distance_km': double,
  ///   'duration_seconds': int,
  ///   'waypoints': List<Map> - coordinates with names,
  ///   'error': String?
  /// }
  static Future<Map<String, dynamic>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String startName,
    required String endName,
  }) async {
    try {
      // OSRM expects: /route/v1/driving/lon,lat;lon,lat
      final String url =
          '$OSRM_BASE_URL/route/v1/driving/$startLng,$startLat;$endLng,$endLat'
          '?overview=full&steps=true&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['code'] == 'Ok' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final geometry = route['geometry'] as Map;

          // Extract coordinates from GeoJSON format
          final List<dynamic> coordinates = geometry['coordinates'] ?? [];
          final polylinePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          // Extract steps for turn-by-turn directions
          final List<dynamic> legs = route['legs'] ?? [];
          List<Map<String, dynamic>> steps = [];

          for (var leg in legs) {
            final legSteps = leg['steps'] as List?;
            if (legSteps != null) {
              for (var step in legSteps) {
                steps.add({
                  'instruction': step['name'] ?? 'Continue',
                  'distance_meters': step['distance'],
                  'duration_seconds': step['duration'],
                  'start_location': {
                    'lat': step['maneuver']['location'][1],
                    'lng': step['maneuver']['location'][0],
                  },
                  'direction': step['maneuver']['type'],
                });
              }
            }
          }

          return {
            'success': true,
            'polyline_points': polylinePoints,
            'distance_meters': route['distance'],
            'distance_km': (route['distance'] as num) / 1000,
            'duration_seconds': (route['duration'] as num).toInt(),
            'duration_minutes': ((route['duration'] as num) / 60).toStringAsFixed(0),
            'steps': steps,
            'start': startName,
            'end': endName,
          };
        } else {
          return {
            'success': false,
            'polyline_points': [],
            'error': 'No route found: ${json['code']}',
          };
        }
      } else {
        return {
          'success': false,
          'polyline_points': [],
          'error': 'OSRM Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'polyline_points': [],
        'error': 'Error fetching route: $e',
      };
    }
  }

  /// Get route with multiple waypoints (useful for multi-stop journeys)
  /// Example: Ndola -> Kitwe -> Lusaka
  static Future<Map<String, dynamic>> getRouteWithWaypoints({
    required List<Map<String, dynamic>> waypoints,
    // waypoints format: [
    //   {'lat': 12.8, 'lng': 28.6, 'name': 'Ndola'},
    //   {'lat': 12.8, 'lng': 28.3, 'name': 'Kitwe'},
    //   {'lat': -15.4, 'lng': 28.3, 'name': 'Lusaka'},
    // ]
  }) async {
    try {
      if (waypoints.length < 2) {
        return {
          'success': false,
          'error': 'At least 2 waypoints required',
        };
      }

      // Format: lng,lat;lng,lat;lng,lat
      String coordinates = waypoints
          .map((wp) => '${wp['lng']},${wp['lat']}')
          .join(';');

      final String url =
          '$OSRM_BASE_URL/route/v1/driving/$coordinates'
          '?overview=full&steps=true&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['code'] == 'Ok' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final geometry = route['geometry'] as Map;

          final List<dynamic> coordinates = geometry['coordinates'] ?? [];
          final polylinePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          List<Map<String, dynamic>> legsSummary = [];
          for (var leg in route['legs'] ?? []) {
            legsSummary.add({
              'distance_km': ((leg['distance'] as num) / 1000).toStringAsFixed(1),
              'duration_minutes': ((leg['duration'] as num) / 60).toStringAsFixed(0),
            });
          }

          return {
            'success': true,
            'polyline_points': polylinePoints,
            'total_distance_km': ((route['distance'] as num) / 1000).toStringAsFixed(1),
            'total_duration_minutes': ((route['duration'] as num) / 60).toStringAsFixed(0),
            'legs': legsSummary,
            'waypoints': waypoints,
          };
        } else {
          return {
            'success': false,
            'error': 'No route found',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'OSRM Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Check if a point is on the route
  /// Uses OSRM match service for most accurate results
  static Future<Map<String, dynamic>> matchPointToRoute({
    required double lat,
    required double lng,
    required List<LatLng> routePoints,
  }) async {
    try {
      if (routePoints.isEmpty) {
        return {
          'on_route': false,
          'error': 'No route points provided',
        };
      }

      // Format coordinates for matching
      String coordinates = routePoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final String userCoord = '$lng,$lat';
      final String url =
          '$OSRM_BASE_URL/match/v1/driving/$userCoord;$coordinates'
          '?overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['code'] == 'Ok' && (json['matchings'] as List).isNotEmpty) {
          final match = json['matchings'][0];
          final confidence = match['confidence'] as num;

          return {
            'on_route': confidence > 0.7,
            'confidence': confidence,
            'message': confidence > 0.7
                ? '✅ You are on the route'
                : '⚠️ Location confidence: ${(confidence * 100).toStringAsFixed(0)}%',
          };
        } else {
          return {
            'on_route': false,
            'confidence': 0,
            'error': json['code'],
          };
        }
      } else {
        return {
          'on_route': false,
          'error': 'Matching service error',
        };
      }
    } catch (e) {
      return {
        'on_route': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Get road network matrix distances (useful for fare calculation)
  /// Returns distances between multiple points
  static Future<Map<String, dynamic>> getDistanceMatrix({
    required List<Map<String, double>> sources,
    required List<Map<String, double>> destinations,
  }) async {
    try {
      if (sources.isEmpty || destinations.isEmpty) {
        return {
          'success': false,
          'error': 'Empty sources or destinations',
        };
      }

      // Prepare coordinate string
      String coordinates = [
        ...sources.map((p) => '${p['lng']},${p['lat']}'),
        ...destinations.map((p) => '${p['lng']},${p['lat']}'),
      ].join(';');

      final String url =
          '$OSRM_BASE_URL/table/v1/driving/$coordinates'
          '?sources=${List.generate(sources.length, (i) => i).join(',')}'
          '&destinations=${List.generate(destinations.length, (i) => sources.length + i).join(',')}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['code'] == 'Ok') {
          return {
            'success': true,
            'distances': json['distances'], // In meters
            'durations': json['durations'], // In seconds
          };
        } else {
          return {
            'success': false,
            'error': json['code'],
          };
        }
      } else {
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Zambia-specific town coordinates for quick reference
  static Map<String, Map<String, double>> zambiaTowns = {
    'Lusaka': {'lat': -15.4167, 'lng': 28.2833},
    'Ndola': {'lat': -12.9667, 'lng': 28.6333},
    'Kitwe': {'lat': -12.8333, 'lng': 28.2667},
    'Livingstone': {'lat': -17.8667, 'lng': 25.8667},
    'Kalomo': {'lat': -17.7167, 'lng': 26.0822},
    'Copperbelt': {'lat': -12.5, 'lng': 28.3},
    'Kabwe': {'lat': -14.3, 'lng': 28.4},
    'Mumba': {'lat': -12.5333, 'lng': 28.4667},
  };
}
