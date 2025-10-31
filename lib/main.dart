import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'modules/driver/driver_home.dart';
import 'modules/passenger/passenger_home.dart';
import 'modules/shared/services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_WEB_API_KEY',
        appId: 'YOUR_WEB_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        authDomain: 'YOUR_AUTH_DOMAIN',
        storageBucket: 'YOUR_STORAGE_BUCKET',
        measurementId: 'YOUR_MEASUREMENT_ID',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocationService>(
          create: (_) => LocationService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'University Bus Tracking',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006E2C)),
          useMaterial3: true,
        ),
        home: const RootHome(),
      ),
    );
  }
}

class RootHome extends StatefulWidget {
  const RootHome({super.key});

  @override
  State<RootHome> createState() => _RootHomeState();
}

class _RootHomeState extends State<RootHome> {
  int _index = 0;
  final _pages = const [_MapHome(), DriverHome(), PassengerHome()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('University Bus Tracking')),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_filled_outlined),
            label: 'Driver',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin_circle_outlined),
            label: 'Passenger',
          ),
        ],
      ),
    );
  }
}

class _MapHome extends StatefulWidget {
  const _MapHome();

  @override
  State<_MapHome> createState() => _MapHomeState();
}

class _MapHomeState extends State<_MapHome> {
  final MapController _controller = MapController();
  LatLng? _initialCenter;
  double _zoom = 15;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      setState(() => _loading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialCenter = LatLng(position.latitude, position.longitude);
      _zoom = 15;
      _loading = false;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_initialCenter == null) {
      return const Center(child: Text('Location permission denied.'));
    }

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(center: _initialCenter, zoom: _zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.university_bus_tracking',
        ),
      ],
    );
  }
}

// TODO: Authentication flow (Firebase Auth) and role-based routing.
// TODO: Admin web dashboard module (routes, buses, drivers management).
