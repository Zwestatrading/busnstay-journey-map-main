import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journey_model.dart';
import '../models/order_model.dart';
import 'dart:async';

/// Service for managing town status and order availability
/// Handles dynamic opening/closing of towns based on bus position
class TownOrderManagementService {
  final SupabaseClient supabaseClient;
  
  BusJourney? _currentJourney;
  StreamSubscription? _positionStreamSubscription;
  final Map<String, StreamSubscription> _townStatusSubscriptions = {};

  TownOrderManagementService({required this.supabaseClient});

  /// ============= INITIALIZATION =============

  /// Load journey and initialize town statuses
  Future<void> initializeJourney(String journeyId) async {
    try {
      print('📍 [INIT] Loading journey $journeyId');

      // Fetch journey data
      final journeyData = await supabaseClient
          .from('journeys')
          .select('*, towns:journey_towns(*)')
          .eq('id', journeyId)
          .single();

      // Parse towns
      final townsList = (journeyData['towns'] as List<dynamic>)
          .map((t) => JourneyTown.fromJson(t as Map<String, dynamic>))
          .toList();

      // Create journey object
      _currentJourney = BusJourney(
        journeyId: journeyData['id'],
        busId: journeyData['bus_id'],
        routeName: journeyData['route_name'],
        departureTime: DateTime.parse(journeyData['departure_time']),
        estimatedArrivalTime: DateTime.parse(journeyData['estimated_arrival_time']),
        towns: townsList,
        currentLatitude: journeyData['current_latitude']?.toDouble() ?? 0.0,
        currentLongitude: journeyData['current_longitude']?.toDouble() ?? 0.0,
        lastPositionUpdate: DateTime.parse(journeyData['last_position_update']),
      );

      print('✅ [INIT] Journey loaded with ${_currentJourney!.towns.length} towns');

      // Set all towns as OPEN initially
      for (final town in _currentJourney!.towns) {
        if (town.status == TownStatus.open) {
          await _persistTownStatus(town);
        }
      }
    } catch (e) {
      print('❌ [ERROR] Failed to initialize journey: $e');
      throw Exception('Failed to load journey: $e');
    }
  }

  /// ============= TOWN AVAILABILITY CHECKS =============

  /// Check if a town is available for new orders
  Future<bool> isTownOrderingAvailable(String townId) async {
    if (_currentJourney == null) {
      throw Exception('Journey not initialized');
    }

    try {
      final town = _currentJourney!.towns.firstWhere(
        (t) => t.townId == townId,
        orElse: () => throw Exception('Town not found in journey'),
      );

      // Quick check on status
      if (!town.isOrderingAvailable) {
        print('🚫 [TOWN] Orders closed for ${town.townName}: ${town.status}');
        return false;
      }

      // Check if should auto-close based on ETA/distance
      if (town.shouldBeClosed()) {
        print('⏱️ [AUTO-CLOSE] Closing ${town.townName} (ETA: ${town.etaToTown}, Distance: ${town.distanceToTown}km)');
        await closeTown(townId);
        return false;
      }

      return true;
    } catch (e) {
      print('❌ [ERROR] Failed to check town availability: $e');
      return false;
    }
  }

  /// Get all towns currently open for orders
  Future<List<JourneyTown>> getAvailableTowns() async {
    if (_currentJourney == null) {
      throw Exception('Journey not initialized');
    }

    return _currentJourney!.towns
        .where((t) => t.isOrderingAvailable)
        .toList();
  }

  /// Get town details with current status
  Future<JourneyTown?> getTownDetails(String townId) async {
    if (_currentJourney == null) {
      return null;
    }

    try {
      return _currentJourney!.towns.firstWhere(
        (t) => t.townId == townId,
        orElse: () => throw Exception('Town not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// ============= TOWN STATUS MANAGEMENT =============

  /// Manually close a town for new orders
  Future<bool> closeTown(String townId) async {
    try {
      if (_currentJourney == null) return false;

      final town = _currentJourney!.towns.firstWhere(
        (t) => t.townId == townId,
        orElse: () => throw Exception('Town not found'),
      );

      if (town.status == TownStatus.open) {
        town.status = TownStatus.closed;
        town.statusChangedAt = DateTime.now();

        await _persistTownStatus(town);
        await _notifyTownStatusChange(town);

        print('🚪 [CLOSE] ${town.townName} closed for new orders');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [ERROR] Failed to close town: $e');
      return false;
    }
  }

  /// Reopen a town for orders (if journey hasn't passed yet)
  Future<bool> reopenTown(String townId) async {
    try {
      if (_currentJourney == null) return false;

      final town = _currentJourney!.towns.firstWhere(
        (t) => t.townId == townId,
        orElse: () => throw Exception('Town not found'),
      );

      if (town.status == TownStatus.closed && town.distanceToTown! > 5.0) {
        town.status = TownStatus.open;
        town.statusChangedAt = DateTime.now();

        await _persistTownStatus(town);
        await _notifyTownStatusChange(town);

        print('🔓 [REOPEN] ${town.townName} reopened for new orders');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [ERROR] Failed to reopen town: $e');
      return false;
    }
  }

  /// Lock a town permanently (bus has passed)
  Future<bool> lockTown(String townId) async {
    try {
      if (_currentJourney == null) return false;

      final town = _currentJourney!.towns.firstWhere(
        (t) => t.townId == townId,
        orElse: () => throw Exception('Town not found'),
      );

      _currentJourney!.lockTown(townId);
      await _persistTownStatus(town);
      await _notifyTownStatusChange(town);

      print('🔒 [LOCK] ${town.townName} locked permanently');
      return true;
    } catch (e) {
      print('❌ [ERROR] Failed to lock town: $e');
      return false;
    }
  }

  /// ============= POSITION TRACKING & AUTO-CLOSE =============

  /// Update bus position and auto-close approaching towns
  Future<void> updateBusPosition({
    required double latitude,
    required double longitude,
  }) async {
    if (_currentJourney == null) return;

    try {
      _currentJourney!.updatePosition(
        latitude: latitude,
        longitude: longitude,
      );

      // Check each town for auto-close
      for (final town in _currentJourney!.towns) {
        if (town.status == TownStatus.open && town.shouldBeClosed()) {
          await closeTown(town.townId);
        }

        // Check if bus has passed the town
        if (town.status == TownStatus.closed &&
            town.distanceToTown! < 0.5) {
          // Bus is at/past the town
          await lockTown(town.townId);
        }
      }

      // Persist updated journey position
      await _persistJourneyPosition();
    } catch (e) {
      print('❌ [ERROR] Failed to update bus position: $e');
    }
  }

  /// Track bus position in real-time and manage town statuses
  void startPositionTracking(Stream<Map<String, dynamic>> positionStream) {
    _positionStreamSubscription = positionStream.listen((position) async {
      await updateBusPosition(
        latitude: position['latitude'] as double,
        longitude: position['longitude'] as double,
      );
    });
  }

  /// ============= ORDER VALIDATION =============

  /// Validate order can be placed for a town
  Future<Map<String, dynamic>> validateOrderFor({
    required String townId,
    required FoodOrder order,
  }) async {
    try {
      // Check town exists and is in current journey
      final town = await getTownDetails(townId);
      if (town == null) {
        return {
          'valid': false,
          'reason': 'Invalid town',
          'townName': null,
        };
      }

      // Check if ordering is available
      final available = await isTownOrderingAvailable(townId);
      if (!available) {
        return {
          'valid': false,
          'reason': 'Orders closed for this town',
          'townName': town.townName,
          'status': town.status.toString().split('.').last,
          'message': town.availabilityMessage,
        };
      }

      // Check if restaurant is still accepting orders
      final restaurantData = await supabaseClient
          .from('restaurants')
          .select('is_active, is_accepting_orders, max_orders_per_stop')
          .eq('id', order.restaurantId)
          .single();

      if (!(restaurantData['is_active'] as bool? ?? false)) {
        return {
          'valid': false,
          'reason': 'Restaurant not active',
        };
      }

      if (!(restaurantData['is_accepting_orders'] as bool? ?? false)) {
        return {
          'valid': false,
          'reason': 'Restaurant not accepting orders',
        };
      }

      // Success
      return {
        'valid': true,
        'townName': town.townName,
        'etaMinutes': town.etaToTown?.inMinutes ?? 0,
        'distanceKm': town.distanceToTown ?? 0.0,
      };
    } catch (e) {
      print('❌ [ERROR] Order validation failed: $e');
      return {
        'valid': false,
        'reason': 'Validation error: $e',
      };
    }
  }

  /// Get suggested alternative towns for closed town
  Future<List<JourneyTown>> getSuggestedAlternativeTowns(String closedTownId) async {
    if (_currentJourney == null) return [];

    try {
      final closedTownerIndex = _currentJourney!.towns
          .indexWhere((t) => t.townId == closedTownId);

      if (closedTownerIndex < 0) return [];

      // Return next 3 open towns
      return _currentJourney!.towns
          .sublist(closedTownerIndex + 1)
          .where((t) => t.isOrderingAvailable)
          .take(3)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ============= PERSISTENCE & NOTIFICATIONS =============

  /// Persist town status to database
  Future<void> _persistTownStatus(JourneyTown town) async {
    try {
      await supabaseClient.from('journey_towns').update({
        'status': town.status.toString().split('.').last,
        'status_changed_at': town.statusChangedAt?.toIso8601String(),
        'eta_to_town': town.etaToTown?.inSeconds,
        'distance_to_town': town.distanceToTown,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', town.townId);
    } catch (e) {
      print('⚠️ [PERSIST] Failed to save town status: $e');
    }
  }

  /// Persist journey position
  Future<void> _persistJourneyPosition() async {
    try {
      if (_currentJourney == null) return;

      await supabaseClient.from('journeys').update({
        'current_latitude': _currentJourney!.currentLatitude,
        'current_longitude': _currentJourney!.currentLongitude,
        'last_position_update': _currentJourney!.lastPositionUpdate.toIso8601String(),
      }).eq('id', _currentJourney!.journeyId);
    } catch (e) {
      print('⚠️ [PERSIST] Failed to save journey position: $e');
    }
  }

  /// Notify all subscribers of town status change
  Future<void> _notifyTownStatusChange(JourneyTown town) async {
    try {
      // Insert notification for real-time updates
      await supabaseClient.from('town_status_updates').insert({
        'id': _generateId('town_update'),
        'journey_id': _currentJourney!.journeyId,
        'town_id': town.townId,
        'town_name': town.townName,
        'new_status': town.status.toString().split('.').last,
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ [NOTIFY] Failed to notify subscribers: $e');
    }
  }

  /// ============= REAL-TIME SUBSCRIPTIONS =============

  /// Subscribe to town status updates
  Stream<JourneyTown> subscribeToTownStatusUpdates(String journeyId) {
    return supabaseClient
        .from('town_status_updates')
        .on(RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: '*',
              schema: 'public',
              table: 'town_status_updates',
              filter: 'journey_id=eq.$journeyId',
            ))
        .stream()
        .asyncMap((event) async {
      final townId = event.payload['town_id'];
      return await getTownDetails(townId) ?? JourneyTown(
        townId: townId,
        townName: event.payload['town_name'],
        latitude: 0,
        longitude: 0,
        pickupStationName: '',
        estimatedStopDuration: Duration.zero,
      );
    });
  }

  /// ============= UTILITIES =============

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix:${timestamp}_${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (i) => chars[(DateTime.now().millisecond + i) % chars.length],
    ).join();
  }

  /// Get current journey
  BusJourney? get currentJourney => _currentJourney;

  /// Cleanup resources
  Future<void> dispose() async {
    await _positionStreamSubscription?.cancel();
    for (final subscription in _townStatusSubscriptions.values) {
      await subscription.cancel();
    }
  }
}
