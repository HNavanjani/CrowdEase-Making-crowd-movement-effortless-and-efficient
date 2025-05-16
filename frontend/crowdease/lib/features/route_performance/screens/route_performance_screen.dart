import 'package:flutter/material.dart';
import '../../../core/http_helper.dart';

class RoutePerformanceScreen extends StatefulWidget {
  const RoutePerformanceScreen({super.key});

  @override
  State<RoutePerformanceScreen> createState() => _RoutePerformanceScreenState();
}

class _RoutePerformanceScreenState extends State<RoutePerformanceScreen> {
  Map<String, dynamic> routeData = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await HttpHelper.get('/route-performance');
      if (response != null && response['route_performance'] != null) {
        setState(() {
          routeData = Map<String, dynamic>.from(response['route_performance']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "No data available";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Failed to load data: $e";
        isLoading = false;
      });
    }
  }

  String getCrowdingLabel(num score) {
    if (score >= 0.1) return "High";
    if (score >= 0.05) return "Moderate";
    return "Low";
  }

  Widget buildRouteCard(String routeId, Map<String, dynamic> data) {
    final stop = data["most_common_stop"] ?? "Unknown stop";
    final crowdLabel = getCrowdingLabel(data["average_crowding_score"]);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📍 $stop", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("🕒 Avg. Delay: ${data["average_delay_minutes"]} mins"),
          Text("👥 Crowding Level: $crowdLabel"),
          Text("🚌 Total Trips: ${data["total_trips"]}"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Performance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: routeData.entries.map((entry) {
                    final routeId = entry.key;
                    final data = Map<String, dynamic>.from(entry.value);
                    return buildRouteCard(routeId, data);
                  }).toList(),
                ),
    );
  }
}
