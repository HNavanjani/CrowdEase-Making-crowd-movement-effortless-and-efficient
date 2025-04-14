import 'package:flutter/material.dart';

final Map<String, String> personalizedTips = {
  'demo@demo.com': 'Based on your past travel, Route 890 is less crowded at 4 PM.',
  'student@crowdease.com': 'Your usual Route 370 is better before 8 AM.',
  'default@demo.com': 'Route 333 tends to be quieter in the evening.',
};

final List<Map<String, dynamic>> routeCrowdData = [
  {
    'route': 'Route 333',
    'level': 'High',
    'icon': Icons.warning
  },
  {
    'route': 'Route 370',
    'level': 'Medium',
    'icon': Icons.directions_bus
  },
  {
    'route': 'Route 890',
    'level': 'Low',
    'icon': Icons.check_circle
  },
  {
    'route': 'Route 420',
    'level': 'Medium',
    'icon': Icons.directions_bus_filled
  },
];
