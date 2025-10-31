import 'package:flutter/material.dart';

import 'bus_tracker.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  String _busId = 'bus_ku_01';

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
        // TODO: Drop location feature for passengers to set/drop stops.
      ],
    );
  }
}
