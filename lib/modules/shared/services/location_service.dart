import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Provides location update utilities for drivers and passengers.
/// - Drivers: periodically send GPS location to Firestore at `/buses/{busId}`
/// - Passengers: listen to real-time location updates to track a bus
class LocationService {
  LocationService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _simulationTimer;

  /// Sends a single location update for a bus.
  Future<void> sendDriverLocation({
    required String busId,
    required LatLng position,
    DateTime? timestamp,
  }) async {
    final data = {
      'lat': position.latitude,
      'lng': position.longitude,
      'updatedAt': (timestamp ?? DateTime.now()).toUtc().millisecondsSinceEpoch,
      // TODO: attach driverId/auth context after integrating Firebase Auth
    };
    await _db.collection('buses').doc(busId).set(data, SetOptions(merge: true));
  }

  /// Returns a stream of `LatLng` for a bus's live location.
  Stream<LatLng?> listenToBusLocation(String busId) {
    return _db.collection('buses').doc(busId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final lat = data['lat'];
      final lng = data['lng'];
      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
      return null;
    });
  }

  /// Starts a simple simulation that sends a location update every [interval]
  /// seconds by mildly moving around the [start] location. Intended for demos.
  void startDriverSimulation({
    required String busId,
    required LatLng start,
    Duration interval = const Duration(seconds: 5),
  }) {
    stopDriverSimulation();
    final random = Random();
    LatLng current = start;
    _simulationTimer = Timer.periodic(interval, (_) {
      // small random walk to simulate movement
      final deltaLat = (random.nextDouble() - 0.5) / 2000.0; // ~50m
      final deltaLng = (random.nextDouble() - 0.5) / 2000.0;
      current = LatLng(
        current.latitude + deltaLat,
        current.longitude + deltaLng,
      );
      sendDriverLocation(busId: busId, position: current);
    });
  }

  void stopDriverSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void dispose() {
    stopDriverSimulation();
  }
}
