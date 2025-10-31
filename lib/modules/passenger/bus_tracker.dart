import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../shared/services/location_service.dart';

class BusTracker extends StatefulWidget {
  const BusTracker({super.key, required this.busId});
  final String busId;

  @override
  State<BusTracker> createState() => _BusTrackerState();
}

class _BusTrackerState extends State<BusTracker> {
  final MapController _controller = MapController();
  final LatLng _initialCenter = const LatLng(22.8456, 89.5403); // Khulna approx
  double _zoom = 13;
  StreamSubscription<LatLng?>? _sub;
  LatLng? _busPosition;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant BusTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busId != widget.busId) {
      _subscribe();
    }
  }

  void _subscribe() {
    _sub?.cancel();
    final service = context.read<LocationService>();
    _sub = service.listenToBusLocation(widget.busId).listen((pos) async {
      if (pos == null) return;
      setState(() => _busPosition = pos);
      _controller.move(pos, _zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    if (_busPosition != null) {
      markers.add(
        Marker(
          point: _busPosition!,
          width: 40,
          height: 40,
          child: const Icon(Icons.directions_bus, color: Colors.red, size: 32),
        ),
      );
    }

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        center: _initialCenter,
        zoom: _zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.university_bus_tracking',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
