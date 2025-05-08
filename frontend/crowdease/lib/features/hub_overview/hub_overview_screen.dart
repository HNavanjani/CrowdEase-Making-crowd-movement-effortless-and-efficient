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
  Map<String, String> routeLabels = {}; // <-- Added
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentTime = _getCurrentTime();
    _fetchRoutesAndPreferences();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return DateFormat('HH:mm').format(now);
  }

  Future<void> _fetchRoutesAndPreferences() async {
    final routeRes = await http.get(Uri.parse("${ApiConstants.baseUrl}/dropdown/routes"));
    if (routeRes.statusCode == 200) {
      final routeList = json.decode(routeRes.body);
      setState(() {
        for (final route in routeList) {
          routeLabels[route['route_id']] =
              "${route['route_short_name']} – ${route['route_long_name']}";
        }
      });
    }

    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/get-preferences/${widget.userId}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        regularRoute = data["regular_route"];
        favoriteRoutes = List<String>.from(data["favorite_routes"]);
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

    final regularRouteLabel = routeLabels[regularRoute] ?? regularRoute ?? "Not selected";

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
                subtitle: Text('Your regular route is: Route $regularRouteLabel'),
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
                final label = routeLabels[routeId] ?? routeId;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus, color: Colors.indigo),
                    title: Text("Route $label"),
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
