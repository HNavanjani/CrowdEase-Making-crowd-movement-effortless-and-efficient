import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:crowdease/features/crowd_map_planner/crowd_map_and_planner_screen.dart';
import '../../core/http_helper.dart';

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
  Map<String, String> routeLabels = {};
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

  String _getHourBand(String time) {
    final hour = int.tryParse(time.split(':')[0]) ?? 0;
    if (hour >= 7 && hour < 9) return "07:00-09:00";
    if (hour >= 9 && hour < 12) return "09:00-12:00";
    if (hour >= 12 && hour < 15) return "12:00-15:00";
    if (hour >= 15 && hour < 18) return "15:00-18:00";
    return "Other";
  }

  String _mapPredictionLabel(String code) {
    switch (code) {
      case "0":
        return "Low";
      case "1":
        return "Medium";
      case "2":
        return "High";
      case "3":
        return "Full";
      default:
        return "Unavailable";
    }
  }

  Future<void> _fetchRoutesAndPreferences() async {
    final routeList = await HttpHelper.get("/dropdown/routes");
    List<String> rawFavorites = [];

    if (routeList != null) {
      setState(() {
        for (final route in routeList) {
          routeLabels[route['route_id']] =
              "${route['route_short_name']} – ${route['route_long_name']}";
        }
      });
    }

    final data = await HttpHelper.get("/get-preferences/${widget.userId}");

    if (data != null) {
      regularRoute = data["regular_route"];
      rawFavorites = List<String>.from(data["favorite_routes"]);

      favoriteRoutes = routeLabels.keys
          .where((fullId) =>
              rawFavorites.any((shortId) => fullId.contains(shortId)))
          .toList();

      setState(() => isLoading = false);
      _predictAllFavorites();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _predictAllFavorites() async {
    for (String route in favoriteRoutes) {
      final hourBand = _getHourBand(currentTime);

      final predictionData = await HttpHelper.post("/predict-crowd", {
        "ROUTE": route,
        "TIMETABLE_HOUR_BAND": hourBand,
        "TRIP_POINT": "Start",
        "TIMETABLE_TIME": currentTime,
        "ACTUAL_TIME": currentTime,
      });

      if (predictionData != null) {
        final predictionCode =
            predictionData["predicted_capacity_bucket_encoded"]?.toString();
        final label = _mapPredictionLabel(predictionCode ?? "");
        setState(() {
          predictions[route] = label;
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
    final suggestion = "Check predictions before you leave to avoid unexpected crowding. Travel 10 minutes earlier to beat the rush!";

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final regularRouteFullId = routeLabels.keys.firstWhere(
      (key) => key.contains(regularRoute ?? ''),
      orElse: () => regularRoute ?? '',
    );

    final regularRouteLabel =
        routeLabels[regularRouteFullId] ?? regularRouteFullId;

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
                leading: const Icon(Icons.person_pin, color: Colors.indigo, size: 36),
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
