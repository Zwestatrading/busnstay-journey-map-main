import 'dart:convert';
import 'package:http/http.dart' as http;

/// Route data returned by the Waze RapidAPI.
class WazeRoute {
  final String distance; // e.g. "320 km"
  final String duration; // e.g. "~4h 15m"

  WazeRoute({required this.distance, required this.duration});
}

/// Calls the Waze RapidAPI (waze.p.rapidapi.com) for driving directions
/// and traffic alerts. Falls back gracefully on network errors.
class WazeService {
  static const String _apiKey =
      '63ebf9afddmsh060d1564382aa31p167836jsndbb5c91f8d8f';
  static const String _host = 'waze.p.rapidapi.com';

  static Map<String, String> get _headers => {
        'x-rapidapi-key': _apiKey,
        'x-rapidapi-host': _host,
        'Content-Type': 'application/json',
      };

  /// Get real driving directions between two coordinate pairs.
  /// Returns null if the API call fails (caller should fall back to estimate).
  static Future<WazeRoute?> getDrivingDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final uri = Uri.https(_host, '/driving-directions', {
        'from': 'lat:$fromLat lng:$fromLng',
        'to': 'lat:$toLat lng:$toLng',
        'vehicle': 'personal',
        'departure_ts': '0',
        'return_json': 'true',
      });

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final routes = data?['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final meters = (route['total_length'] as num?)?.toDouble() ?? 0;
          final seconds = (route['total_drive_time'] as num?)?.toInt() ?? 0;

          final km = (meters / 1000).round();
          final hours = seconds ~/ 3600;
          final minutes = (seconds % 3600) ~/ 60;

          final String duration;
          if (hours > 0 && minutes > 0) {
            duration = '~${hours}h ${minutes}m';
          } else if (hours > 0) {
            duration = '~${hours}h';
          } else {
            duration = '~${minutes}m';
          }

          return WazeRoute(distance: '$km km', duration: duration);
        }
      }
    } catch (_) {
      // Network error or parse error — caller falls back to geolocator estimate
    }
    return null;
  }

  /// Get traffic alerts and jams within a bounding box.
  /// Used to show traffic incidents on the map background.
  static Future<List<Map<String, dynamic>>> getAlertsAndJams({
    required double bottomLeftLat,
    required double bottomLeftLng,
    required double topRightLat,
    required double topRightLng,
    int maxAlerts = 10,
    int maxJams = 10,
  }) async {
    try {
      final uri = Uri.https(_host, '/alerts-and-jams', {
        'bottom_left': '$bottomLeftLat,$bottomLeftLng',
        'top_right': '$topRightLat,$topRightLng',
        'radius_units': 'KM',
        'max_alerts': '$maxAlerts',
        'max_jams': '$maxJams',
      });

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final alerts = data?['alerts'] as List? ?? [];
        return alerts.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Silently ignore — traffic overlay is non-critical
    }
    return [];
  }
}
