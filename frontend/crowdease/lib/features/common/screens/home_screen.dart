// crowd_ease_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../bus/screens/live_bus_positions.dart';
import '../../hub_overview/hub_overview_screen.dart';
import '../../crowd_map_planner/crowd_map_and_planner_screen.dart';
import '../../crowd_feedback/feedback_screen.dart';
import '../../preferences/screens/user_preferences_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../insights/screens/travel_history_screen.dart';
import '../../alerts/screens/alerts_and_notifications.dart';
import '../../personalized_suggestions/screens/personalize_suggestions_screen.dart';
import '../../simulated_forecast/screens/simulated_forecast_screen.dart';
import '../../route_performance/screens/route_performance_screen.dart';
import '../../help_and_about/screens/help_and_about_screen.dart';
import '../../../core/http_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  Timer? _pollingTimer;
  bool _hasPreferences = false;
  bool _checkingPrefs = true;
  String? regularRoute;
  List<String> favoriteRoutes = [];

  @override
  void initState() {
    super.initState();
    _startPollingForNewModel();
    _checkUserPreferences();
  }

  void _checkUserPreferences() async {
    final data = await HttpHelper.get("/get-preferences/${user?.uid}");
    if (data != null) {
      setState(() {
        _hasPreferences = true;
        _checkingPrefs = false;
        regularRoute = data["regular_route"];
        favoriteRoutes = List<String>.from(data["favorite_routes"]);
      });
    } else {
      setState(() {
        _hasPreferences = false;
        _checkingPrefs = false;
      });
    }
  }

  void _startPollingForNewModel() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final data = await HttpHelper.get("/check-new-model");
      if (data != null && data["new_model_available"] == true) {
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
    });
  }

  void _manualCheckNewModel() async {
    final data = await HttpHelper.get("/check-new-model");
    if (data != null && data["new_model_available"] == true) {
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
        const PopupMenuItem(value: 'logout', child: Text("Logout")),
      ],
    );

    if (result == 'logout') {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  List<Widget> _buildScreens() {
    return [
      _checkingPrefs
          ? const Center(child: CircularProgressIndicator())
          : _hasPreferences
              ? HubOverviewScreen(
                  userId: FirebaseAuth.instance.currentUser?.uid ?? "default_user",
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "You haven’t set your preferred routes yet.\nTap below to personalize your commute.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserPreferencesScreen(userId: user?.uid ?? ''),
                            ),
                          );
                          _checkUserPreferences();
                        },
                        child: const Text("Set Preferences"),
                      ),
                    ],
                  ),
                ),
     const AlertsAndNotificationsScreen(),
      CrowdMapAndPlannerScreen(),
      FeedbackScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

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
                _checkUserPreferences();
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
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Travel History & Insights'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (_) => const TravelHistoryScreen()),
                  MaterialPageRoute(builder: (_) => TravelHistoryScreen(userId: user?.uid ?? ''),),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notification_important),
              title: const Text('Alerts & Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsAndNotificationsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Personalized Suggestions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonalizedSuggestionsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('Simulated Forecast'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SimulatedForecastScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Route Performance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutePerformanceScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Route Preferences'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserPreferencesScreen(userId: user?.uid ?? '')),
                );
                _checkUserPreferences();
              },
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
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpAboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
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
