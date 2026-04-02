import 'package:geolocator/geolocator.dart';

/// Town status in a journey
enum TownStatus {
  open,      // New orders still being accepted
  closed,    // Bus approaching (ETA < cutoff), no new orders
  locked,    // Bus has passed, permanently closed
}

/// Represents a stop along the bus journey
class JourneyTown {
  final String townId;
  final String townName;
  final double latitude;
  final double longitude;
  final String pickupStationName;
  final Duration estimatedStopDuration;
  
  // Status management
  TownStatus status;
  DateTime? statusChangedAt;
  Duration? etaToTown;
  double? distanceToTown;
  
  // Cutoff configuration
  final Duration orderCutoffBeforeETA;  // e.g., 10 minutes
  final double orderCutoffByDistance;   // e.g., 3 km

  JourneyTown({
    required this.townId,
    required this.townName,
    required this.latitude,
    required this.longitude,
    required this.pickupStationName,
    required this.estimatedStopDuration,
    this.status = TownStatus.open,
    this.statusChangedAt,
    this.etaToTown,
    this.distanceToTown,
    this.orderCutoffBeforeETA = const Duration(minutes: 10),
    this.orderCutoffByDistance = 3.0, // km
  });

  /// Check if ordering is still available for this town
  bool get isOrderingAvailable => status == TownStatus.open;

  /// Get a user-friendly message about town availability
  String get availabilityMessage {
    switch (status) {
      case TownStatus.open:
        if (etaToTown != null) {
          return 'Open • ETA: ${formatDuration(etaToTown!)}';
        }
        return 'Open for orders';
      case TownStatus.closed:
        return 'Closed • Bus arriving soon';
      case TownStatus.locked:
        return 'Closed • Bus has passed';
    }
  }

  /// Check if town should be closed based on current ETA/distance
  bool shouldBeClosed() {
    if (status != TownStatus.open) return false;

    // Time-based cutoff
    if (etaToTown != null && etaToTown! <= orderCutoffBeforeETA) {
      return true;
    }

    // Distance-based cutoff
    if (distanceToTown != null && distanceToTown! <= orderCutoffByDistance) {
      return true;
    }

    return false;
  }

  /// Update status based on current position
  void updateStatus({
    required Duration newEta,
    required double newDistance,
  }) {
    etaToTown = newEta;
    distanceToTown = newDistance;

    if (shouldBeClosed() && status == TownStatus.open) {
      status = TownStatus.closed;
      statusChangedAt = DateTime.now();
    }
  }

  /// Mark town as locked (bus has passed)
  void lockTown() {
    if (status != TownStatus.locked) {
      status = TownStatus.locked;
      statusChangedAt = DateTime.now();
    }
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
    'townId': townId,
    'townName': townName,
    'latitude': latitude,
    'longitude': longitude,
    'pickupStationName': pickupStationName,
    'estimatedStopDuration': estimatedStopDuration.inSeconds,
    'status': status.toString().split('.').last,
    'statusChangedAt': statusChangedAt?.toIso8601String(),
    'etaToTown': etaToTown?.inSeconds,
    'distanceToTown': distanceToTown,
    'orderCutoffBeforeETA': orderCutoffBeforeETA.inSeconds,
    'orderCutoffByDistance': orderCutoffByDistance,
  };

  /// Create from JSON
  factory JourneyTown.fromJson(Map<String, dynamic> json) {
    return JourneyTown(
      townId: json['townId'] as String,
      townName: json['townName'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      pickupStationName: json['pickupStationName'] as String,
      estimatedStopDuration: Duration(seconds: json['estimatedStopDuration'] ?? 0),
      status: _parseTownStatus(json['status'] ?? 'open'),
      statusChangedAt: json['statusChangedAt'] != null 
          ? DateTime.parse(json['statusChangedAt']) 
          : null,
      etaToTown: json['etaToTown'] != null 
          ? Duration(seconds: json['etaToTown']) 
          : null,
      distanceToTown: (json['distanceToTown'] as num?)?.toDouble(),
      orderCutoffBeforeETA: Duration(
        seconds: json['orderCutoffBeforeETA'] ?? 600, // default 10 min
      ),
      orderCutoffByDistance: json['orderCutoffByDistance'] ?? 3.0,
    );
  }
}

/// Active bus journey
class BusJourney {
  final String journeyId;
  final String busId;
  final String routeName;
  final DateTime departureTime;
  final DateTime estimatedArrivalTime;
  
  List<JourneyTown> towns;
  double currentLatitude;
  double currentLongitude;
  DateTime lastPositionUpdate;
  
  bool isActive;

  BusJourney({
    required this.journeyId,
    required this.busId,
    required this.routeName,
    required this.departureTime,
    required this.estimatedArrivalTime,
    required this.towns,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.lastPositionUpdate,
    this.isActive = true,
  });

  /// Get the next upcoming town (not locked)
  JourneyTown? get nextTown => towns
      .firstWhere(
        (t) => t.status != TownStatus.locked,
        orElse: () => towns.isEmpty ? null : towns.last,
      )
      .let((t) => t == null ? null : t);

  /// Get all towns still open for orders
  List<JourneyTown> get openTowns => towns
      .where((t) => t.isOrderingAvailable)
      .toList();

  /// Update bus position and refresh town statuses
  void updatePosition({
    required double latitude,
    required double longitude,
  }) {
    currentLatitude = latitude;
    currentLongitude = longitude;
    lastPositionUpdate = DateTime.now();

    _recalculateTownStatuses();
  }

  /// Recalculate ETA and distance for all towns
  void _recalculateTownStatuses() {
    final currentPos = Position(
      latitude: currentLatitude,
      longitude: currentLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    for (final town in towns) {
      if (town.status == TownStatus.locked) continue;

      final townPos = Position(
        latitude: town.latitude,
        longitude: town.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      // Calculate distance using Haversine formula
      final distance = _haversineDistance(currentPos, townPos);
      
      // Estimate ETA (assuming average speed of 80 km/h on highway)
      final avgSpeedKmH = 80.0;
      final etaSeconds = (distance / avgSpeedKmH) * 3600;
      final eta = Duration(seconds: etaSeconds.toInt());

      town.updateStatus(
        newEta: eta,
        newDistance: distance,
      );
    }
  }

  /// Calculate distance between two positions using Haversine formula
  static double _haversineDistance(Position pos1, Position pos2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(pos2.latitude - pos1.latitude);
    final dLon = _toRad(pos2.longitude - pos1.longitude);
    final lat1 = _toRad(pos1.latitude);
    final lat2 = _toRad(pos2.latitude);

    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.sin(dLon / 2) *
            Math.sin(dLon / 2) *
            Math.cos(lat1) *
            Math.cos(lat2);

    final c = 2 * Math.asin(Math.sqrt(a));
    return earthRadiusKm * c;
  }

  static double _toRad(double degrees) => degrees * (Math.pi / 180);

  /// Mark a town as locked (bus passed)
  void lockTown(String townId) {
    final town = towns.firstWhere(
      (t) => t.townId == townId,
      orElse: () => towns.isEmpty ? null : towns.first,
    );
    town?.lockTown();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'journeyId': journeyId,
    'busId': busId,
    'routeName': routeName,
    'departureTime': departureTime.toIso8601String(),
    'estimatedArrivalTime': estimatedArrivalTime.toIso8601String(),
    'towns': towns.map((t) => t.toJson()).toList(),
    'currentLatitude': currentLatitude,
    'currentLongitude': currentLongitude,
    'lastPositionUpdate': lastPositionUpdate.toIso8601String(),
    'isActive': isActive,
  };

  /// Create from JSON
  factory BusJourney.fromJson(Map<String, dynamic> json) {
    return BusJourney(
      journeyId: json['journeyId'] as String,
      busId: json['busId'] as String,
      routeName: json['routeName'] as String,
      departureTime: DateTime.parse(json['departureTime']),
      estimatedArrivalTime: DateTime.parse(json['estimatedArrivalTime']),
      towns: (json['towns'] as List<dynamic>)
          .map((t) => JourneyTown.fromJson(t as Map<String, dynamic>))
          .toList(),
      currentLatitude: json['currentLatitude'] as double,
      currentLongitude: json['currentLongitude'] as double,
      lastPositionUpdate: DateTime.parse(json['lastPositionUpdate']),
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Helper function for Duration formatting
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}

/// Extension for error handling
extension on Object? {
  T? let<T>(T Function(dynamic) f) {
    if (this != null) {
      return f(this);
    }
    return null;
  }
}

// Required imports
import 'dart:math' as Math;
