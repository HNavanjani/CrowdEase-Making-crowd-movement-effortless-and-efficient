import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crowdease/features/crowd_map_planner/crowd_map_and_planner_screen.dart';
import 'package:crowdease/core/api_constants.dart';

class HubOverviewScreen extends StatefulWidget {
  final String userId;

  const HubOverviewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HubOverviewScreen> createState() => _HubOverviewScreenState();
}

class _HubOverviewScreenState extends State<HubOverviewScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String currentTime = "";
  Map<String, String> predictions = {};
  String? regularRoute;
  List<String> favoriteRoutes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentTime = _getCurrentTime();
    _fetchUserPreferences();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return DateFormat('HH:mm').format(now);
  }

  Future<void> _fetchUserPreferences() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/get-preferences/${widget.userId}"),
    );
    print("****************");
    print(widget.userId);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        regularRoute = data["regular_route"];
        favoriteRoutes = List<String>.from(data["favorite_routes"]);
        print("✅ Loaded favorite routes from HomeScreen: $favoriteRoutes");
        isLoading = false;
      });
      _predictAllFavorites();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _predictAllFavorites() async {
    for (String route in favoriteRoutes) {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/predict-crowd"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ROUTE": route,
          "TIMETABLE_HOUR_BAND": "07:00-09:00",
          "TRIP_POINT": "Start",
          "TIMETABLE_TIME": currentTime,
          "ACTUAL_TIME": currentTime,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          predictions[route] = json.decode(response.body);
        });
      } else {
        setState(() {
          predictions[route] = "Unavailable";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = user?.displayName ?? "Commuter";
    final suggestion = "Avoid peak time routes between 5 PM – 6 PM for a better commute.";

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.person_pin, color: Colors.indigo, size: 36),
                title: Text(
                  'Welcome, $userName!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Your regular route is: Route ${regularRoute ?? "Not selected"}'),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Current Route Crowd Predictions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (favoriteRoutes.isEmpty)
              const Text("No saved routes.")
            else
              ...favoriteRoutes.map((routeId) {
                final prediction = predictions[routeId] ?? "Loading...";
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus, color: Colors.indigo),
                    title: Text("Route $routeId"),
                    subtitle: Text("Crowd Prediction: $prediction (Checked at $currentTime)"),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/alerts'),
                  icon: const Icon(Icons.notifications, color: Colors.indigo),
                  label: const Text("See Alerts"),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CrowdMapAndPlannerScreen()),
                    );
                  },
                  icon: const Icon(Icons.alt_route, color: Colors.indigo),
                  label: const Text("Plan Journey"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
