import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../bus/screens/live_bus_positions.dart';
import '../../hub_overview/hub_overview_screen.dart';
import '../../crowd_map_planner/crowd_map_and_planner_screen.dart';
import '../../crowd_feedback/feedback_screen.dart';
import 'package:crowdease/core/api_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  Timer? _pollingTimer;

  final List<Widget> _screens = [
    HubOverviewScreen(), // F1
    const Center(child: Text('Alerts & Personalized Suggestions')),
    CrowdMapAndPlannerScreen(), // F2
    FeedbackScreen(), // Feedback
  ];

  @override
  void initState() {
    super.initState();
    _startPollingForNewModel();
  }

  void _startPollingForNewModel() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/check-new-model"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["new_model_available"] == true) {
          _pollingTimer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New predictions available'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    });
  }

  void _manualCheckNewModel() async {
    final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/check-new-model"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["new_model_available"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New predictions available'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showProfileMenu() async {
    final result = await showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 10, 100),
      items: [
        PopupMenuItem(
          value: 'profile',
          child: Text(user?.displayName ?? 'Profile'),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Text("Logout"),
        ),
      ],
    );

    if (result == 'logout') {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrowdEase'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualCheckNewModel,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(user?.photoURL ?? ''),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.displayName ?? 'Guest',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Destinations (Hub Overview)'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text('Directions (Journey Planner)'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Submit Feedback'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Travel History & Insights'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notification_important),
              title: const Text('Alerts & Notifications'),
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Personalized Suggestions'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('Simulated Forecast'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Route Performance'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('Live Bus Positions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveBusPositions()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Help / About'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
        ],
      ),
    );
  }
}
