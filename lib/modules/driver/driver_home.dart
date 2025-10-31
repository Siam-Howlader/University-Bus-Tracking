import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../shared/services/location_service.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _simulating = false;
  String _busId = 'bus_ku_01';
  LatLng? _center;
  double _zoom = 15;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _liveSub;
  bool _goingLive = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      _zoom = 15;
    });
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _toggleSimulation() async {
    final loc = context.read<LocationService>();
    if (_simulating) {
      loc.stopDriverSimulation();
      setState(() => _simulating = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final start = LatLng(position.latitude, position.longitude);
    loc.startDriverSimulation(
      busId: _busId,
      start: start,
      interval: const Duration(seconds: 5),
    );
    setState(() => _simulating = true);
  }

  Future<void> _toggleGoLive() async {
    if (_goingLive) {
      await _liveSub?.cancel();
      setState(() => _goingLive = false);
      return;
    }

    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    final loc = context.read<LocationService>();
    _liveSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15, // meters
          ),
        ).listen((position) {
          loc.sendDriverLocation(
            busId: _busId,
            position: LatLng(position.latitude, position.longitude),
          );
        });
    setState(() => _goingLive = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _center == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Bus ID',
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: _busId),
                          onSubmitted: (v) => setState(
                            () => _busId = v.trim().isEmpty ? _busId : v.trim(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _toggleSimulation,
                        icon: Icon(
                          _simulating
                              ? Icons.stop_circle_outlined
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_simulating ? 'Stop' : 'Simulate'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _toggleGoLive,
                        icon: Icon(
                          _goingLive
                              ? Icons.podcasts_rounded
                              : Icons.podcasts_outlined,
                        ),
                        label: Text(_goingLive ? 'Live On' : 'Go Live'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(center: _center, zoom: _zoom),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                        userAgentPackageName:
                            'com.example.university_bus_tracking',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _goingLive
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _goingLive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _goingLive
                              ? 'Streaming real GPS to backend...'
                              : 'Tap Go Live to stream real GPS updates.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    context.read<LocationService>().stopDriverSimulation();
    _liveSub?.cancel();
    super.dispose();
  }
}
