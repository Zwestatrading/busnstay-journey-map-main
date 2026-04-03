/// Enhanced maps service with real routing and location validation
/// Integrates Google Directions API and OpenStreetMap with location validation

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'directions_service.dart';
import 'location_validation_service.dart';
import 'openstreetmap_routing_service.dart';

class EnhancedMapsService {
  final DirectionsService directionsService;

  EnhancedMapsService({required this.directionsService});

  // ===== JOURNEY ROUTE PLANNING =====

  /// Plan a journey with real road geometry and location validation
  /// Returns route polyline and validates user location
  Future<Map<String, dynamic>> planJourneyRoute({
    required String startTown,
    required String endTown,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required Position userLocation,
    bool useOpenStreetMap = true, // Use OSM instead of Google (cheaper)
  }) async {
    try {
      // Use OpenStreetMap for cost-effective routing
      if (useOpenStreetMap) {
        final osmRoute = await OpenStreetMapRoutingService.getRoute(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
          startName: startTown,
          endName: endTown,
        );

        if (!osmRoute['success']) {
          return {
            'success': false,
            'error': 'Could not retrieve route: ${osmRoute['error']}',
          };
        }

        // Validate user location against the route
        final polylinePoints = osmRoute['polyline_points'] as List<LatLng>;
        final validation = await _validateLocationOnRoute(
          userLocation: userLocation,
          routePoints: polylinePoints,
          startTown: startTown,
          endTown: endTown,
        );

        return {
          'success': true,
          'route_provider': 'OpenStreetMap',
          'polyline_points': polylinePoints,
          'distance_km': osmRoute['distance_km'],
          'duration_minutes': osmRoute['duration_minutes'],
          'steps': osmRoute['steps'],
          'location_validation': validation,
          'is_user_on_route': validation['valid'],
          'map_style': _getMapStyleForRegion(startTown, endTown),
        };
      } else {
        // Fallback to Google Directions API
        final googleRoute = await directionsService.getDirections(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
          mode: 'driving',
        );

        if (!googleRoute['success']) {
          return {'success': false, 'error': 'Could not retrieve route'};
        }

        final polylinePoints = googleRoute['polyline_points'] as List<LatLng>;
        final validation = await _validateLocationOnRoute(
          userLocation: userLocation,
          routePoints: polylinePoints,
          startTown: startTown,
          endTown: endTown,
        );

        return {
          'success': true,
          'route_provider': 'Google Directions',
          'polyline_points': polylinePoints,
          'distance_km': googleRoute['distance_km'],
          'duration_minutes': googleRoute['duration_text'],
          'steps': googleRoute['steps'],
          'location_validation': validation,
          'is_user_on_route': validation['valid'],
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error planning route: $e'};
    }
  }

  /// Get alternative routes with multiple options
  /// Useful for showing different route options
  Future<Map<String, dynamic>> getAlternativeRoutes({
    required String startTown,
    required String endTown,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // Get alternatives from OpenStreetMap
      final result = await OpenStreetMapRoutingService.getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        startName: startTown,
        endName: endTown,
      );

      if (result['success']) {
        return {
          'success': true,
          'primary_route': {
            'polyline': result['polyline_points'],
            'distance_km': result['distance_km'],
            'duration_minutes': result['duration_minutes'],
          },
          'provider': 'OpenStreetMap',
        };
      } else {
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting alternative routes: $e',
      };
    }
  }

  // ===== NDOLA-LUSAKA SPECIFIC FIX =====

  /// Fix for Ndola-Lusaka route mapping
  /// Ensures proper routing along actual road network
  Future<Map<String, dynamic>> getAccurateNdolaLusakaRoute({
    required Position userLocation,
  }) async {
    try {
      // Ndola coordinates: -12.9667, 28.6333
      // Lusaka coordinates: -15.4167, 28.2833

      const startLat = -12.9667;
      const startLng = 28.6333;
      const endLat = -15.4167;
      const endLng = 28.2833;

      print('🗺️ Planning Ndola → Lusaka route...');

      final route = await OpenStreetMapRoutingService.getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        startName: 'Ndola',
        endName: 'Lusaka',
      );

      if (!route['success']) {
        print('❌ Route planning failed: ${route['error']}');
        return {'success': false, 'error': 'Unable to retrieve route'};
      }

      // Validate user is on route
      final polylinePoints = route['polyline_points'] as List<LatLng>;
      final validation =
          await LocationValidationService.validateJourneyLocation(
            userLocation: userLocation,
            routePoints: polylinePoints
                .map((p) => {'lat': p.latitude, 'lng': p.longitude})
                .toList(),
            startTown: 'Ndola',
            endTown: 'Lusaka',
          );

      print('✅ Ndola-Lusaka route retrieved successfully');
      print('📍 Route distance: ${route['distance_km']} km');
      print('⏱️ Estimated time: ${route['duration_minutes']}');

      return {
        'success': true,
        'polyline_points': polylinePoints,
        'distance_km': route['distance_km'],
        'duration_minutes': route['duration_minutes'],
        'distance_display':
            '${(route['distance_km'] as num).toStringAsFixed(1)} km',
        'duration_display': '${route['duration_minutes']} minutes',
        'steps': route['steps'],
        'contains_waypoints': [
          {'name': 'Ndola', 'lat': startLat, 'lng': startLng},
          {'name': 'Kabwe', 'lat': -14.3, 'lng': 28.4}, // Via Kabwe
          {'name': 'Lusaka', 'lat': endLat, 'lng': endLng},
        ],
        'markers': {
          'start': {
            'position': LatLng(startLat, startLng),
            'title': 'Ndola',
            'infoWindow': 'Start point - Ndola Main Station',
          },
          'end': {
            'position': LatLng(endLat, endLng),
            'title': 'Lusaka',
            'infoWindow': 'End point - Lusaka Main Station',
          },
        },
        'location_validation': validation,
      };
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false,
        'error': 'Error retrieving Ndola-Lusaka route: $e',
      };
    }
  }

  // ===== INTERNAL VALIDATION LOGIC =====

  /// Internal method to validate user location on route
  Future<Map<String, dynamic>> _validateLocationOnRoute({
    required Position userLocation,
    required List<LatLng> routePoints,
    required String startTown,
    required String endTown,
  }) {
    return LocationValidationService.validateJourneyLocation(
      userLocation: userLocation,
      routePoints: routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      startTown: startTown,
      endTown: endTown,
    );
  }

  /// Get map styling for specific region
  Map<String, dynamic> _getMapStyleForRegion(String startTown, String endTown) {
    return {
      'zoom_level': 10,
      'center_zoom': 9,
      'tilt_angle': 0,
      'bearing': 0,
      'min_zoom': 8,
      'max_zoom': 20,
      'polyline_color': '#1F5DDE', // Blue
      'polyline_width': 5,
      'start_marker_color': '#4CAF50', // Green
      'end_marker_color': '#F44336', // Red
    };
  }

  // ===== MAP DISPLAY UTILITIES =====

  /// Create polyline for map display
  static Set<Polyline> createPolyLines({
    required List<LatLng> routePoints,
    required Color routeColor,
  }) {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: routeColor,
        width: 5,
        geodesic: true,
        patterns: [PatternItem.dash(30), PatternItem.gap(20)],
      ),
    };
  }

  /// Create markers for start and end points
  static Set<Marker> createJourneyMarkers({
    required String startTown,
    required double startLat,
    required double startLng,
    required String endTown,
    required double endLat,
    required double endLng,
  }) {
    return {
      // Start marker (green)
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startLat, startLng),
        infoWindow: InfoWindow(
          title: startTown,
          snippet: 'Journey starts here',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      // End marker (red)
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(endLat, endLng),
        infoWindow: InfoWindow(title: endTown, snippet: 'Journey ends here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  /// Create circles to show coverage areas
  static Set<Circle> createCoverageCircles({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    return {
      Circle(
        circleId: const CircleId('coverage'),
        center: LatLng(centerLat, centerLng),
        radius: radiusMeters,
        fillColor: const Color.fromARGB(50, 66, 133, 244),
        strokeColor: const Color.fromARGB(150, 66, 133, 244),
        strokeWidth: 2,
      ),
    };
  }
}
