import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  CameraPosition? _camera;
  final Completer<GoogleMapController> _mapController = Completer();

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
      _camera = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _camera == null
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
                    ],
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: _camera!,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (c) => _mapController.complete(c),
                  ),
                ),
                // TODO: Hook real GPS background updates for production drivers.
              ],
            ),
    );
  }

  @override
  void dispose() {
    context.read<LocationService>().stopDriverSimulation();
    super.dispose();
  }
}
