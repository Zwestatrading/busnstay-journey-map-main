import 'package:flutter/material.dart';
import '../models/journey_model.dart';
import '../main.dart';

class BusOperatorDashboardPage extends StatefulWidget {
  final String journeyId;
  final String routeName;

  const BusOperatorDashboardPage({
    Key? key,
    required this.journeyId,
    required this.routeName,
  }) : super(key: key);

  @override
  _BusOperatorDashboardPageState createState() =>
      _BusOperatorDashboardPageState();
}

class _BusOperatorDashboardPageState extends State<BusOperatorDashboardPage> {
  BusJourney? _journey;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeJourney();
  }

  Future<void> _initializeJourney() async {
    try {
      print('📍 [BUS] Initializing journey ${widget.journeyId}');
      await AppServices.townService.initializeJourney(widget.journeyId);
      setState(() {
        _journey = AppServices.townService.currentJourney;
        _isInitialized = true;
      });
      print('✅ [BUS] Journey initialized with ${_journey?.towns.length} towns');

      // TODO: Start position tracking with GPS
      // AppServices.townService.startPositionTracking(gpsStream);
    } catch (e) {
      print('❌ [ERROR] Failed to initialize journey: $e');
      setState(() {
        _errorMessage = 'Failed to load journey: $e';
      });
    }
  }

  Future<void> _simulatePositionUpdate({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await AppServices.townService.updateBusPosition(
        latitude: latitude,
        longitude: longitude,
      );
      setState(() {
        _journey = AppServices.townService.currentJourney;
      });
      _showSnackBar('📍 Position updated', Colors.blue);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.routeName),
          backgroundColor: Colors.green.shade600,
        ),
        body: Center(
          child: _errorMessage != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red.shade300),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _initializeJourney,
                      child: Text('Retry'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading journey...'),
                  ],
                ),
        ),
      );
    }

    if (_journey == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.routeName)),
        body: Center(child: Text('Journey data not available')),
      );
    }

    final openTowns =
        _journey!.towns.where((t) => t.isOrderingAvailable).toList();
    final closedTowns = _journey!.towns
        .where((t) => t.status == TownStatus.closed)
        .toList();
    final lockedTowns = _journey!.towns
        .where((t) => t.status == TownStatus.locked)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status overview
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journey Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusCard('🟢 Open', openTowns.length, Colors.green),
                      _buildStatusCard('🟡 Closed', closedTowns.length, Colors.orange),
                      _buildStatusCard('🔒 Locked', lockedTowns.length, Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Divider(),

            // Bus position (simulation)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus Position',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Current: ${_journey!.currentLatitude.toStringAsFixed(4)}, '
                    '${_journey!.currentLongitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Simulation buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _simulatePositionUpdate(
                            latitude: -15.3875,
                            longitude: 28.2833,
                          ),
                          icon: Icon(Icons.my_location),
                          label: Text('Lusaka'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _simulatePositionUpdate(
                            latitude: -14.8241,
                            longitude: 28.0921,
                          ),
                          icon: Icon(Icons.my_location),
                          label: Text('Monze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Divider(),

            // Towns list
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Stops',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),

            // Towns
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _journey!.towns.length,
              itemBuilder: (context, index) {
                final town = _journey!.towns[index];
                return _buildTownCard(town);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
          SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTownCard(JourneyTown town) {
    final statusColor = _getTownStatusColor(town.status);
    final statusIcon = _getTownStatusIcon(town.status);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.left(color: statusColor, width: 4),
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$statusIcon ${town.townName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    town.pickupStationName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  town.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (town.etaToTown != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ ETA',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${town.etaToTown!.inMinutes} min',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              if (town.distanceToTown != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Distance',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${town.distanceToTown!.toStringAsFixed(1)} km',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cut-off',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${town.orderCutoffBeforeETA.inMinutes}m / ${town.orderCutoffByDistance.toStringAsFixed(1)}km',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (town.availabilityMessage.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              town.availabilityMessage,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTownStatusColor(TownStatus status) {
    switch (status) {
      case TownStatus.open:
        return Colors.green;
      case TownStatus.closed:
        return Colors.orange;
      case TownStatus.locked:
        return Colors.red;
    }
  }

  String _getTownStatusIcon(TownStatus status) {
    switch (status) {
      case TownStatus.open:
        return '🟢';
      case TownStatus.closed:
        return '🟡';
      case TownStatus.locked:
        return '🔒';
    }
  }
}
