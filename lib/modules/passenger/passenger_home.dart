import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'bus_tracker.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  String _busId = 'bus_ku_01';
  LatLng? _myStop;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Bus ID to follow',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _busId),
                  onSubmitted: (v) => setState(
                    () => _busId = v.trim().isEmpty ? _busId : v.trim(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => setState(() {}),
                child: const Text('Track'),
              ),
            ],
          ),
        ),
        Expanded(child: BusTracker(busId: _busId)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _myStop == null
                      ? 'Set your stop at your current location.'
                      : 'Stop set at: ${_myStop!.latitude.toStringAsFixed(5)}, ${_myStop!.longitude.toStringAsFixed(5)}',
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: _busy ? null : _setStopAtCurrentLocation,
                child: _busy ? const Text('Working...') : const Text('Set Stop'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _busy || _myStop == null ? null : _clearStop,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setStopAtCurrentLocation() async {
    setState(() => _busy = true);
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) return;
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      await FirebaseFirestore.instance
          .collection('passengerStops')
          .doc('default')
          .set({
        'lat': latLng.latitude,
        'lng': latLng.longitude,
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      setState(() => _myStop = latLng);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearStop() async {
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance
          .collection('passengerStops')
          .doc('default')
          .delete();
      setState(() => _myStop = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
