import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../shared/services/location_service.dart';

class BusTracker extends StatefulWidget {
  const BusTracker({super.key, required this.busId});
  final String busId;

  @override
  State<BusTracker> createState() => _BusTrackerState();
}

class _BusTrackerState extends State<BusTracker> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition _camera = const CameraPosition(
    target: LatLng(22.8456, 89.5403),
    zoom: 13,
  ); // Khulna approx
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
      final controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newLatLng(pos));
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    if (_busPosition != null) {
      markers.add(
        Marker(
          markerId: MarkerId(widget.busId),
          position: _busPosition!,
          infoWindow: InfoWindow(title: 'Bus ${widget.busId}'),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: _camera,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (c) => _controller.complete(c),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
