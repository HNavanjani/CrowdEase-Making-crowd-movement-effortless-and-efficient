import 'package:flutter/material.dart';
import 'features/bus/screens/live_bus_positions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrowdEase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LiveBusPositions(),
    );
  }
}
