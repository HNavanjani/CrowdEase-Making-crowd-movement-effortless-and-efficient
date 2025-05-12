import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/http_helper.dart';

class LiveBusPositions extends StatefulWidget {
  const LiveBusPositions({super.key});

  @override
  State<LiveBusPositions> createState() => _LiveBusPositionsState();
}

class _LiveBusPositionsState extends State<LiveBusPositions> {
  final user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> allBuses = [];
  List<Map<String, dynamic>> filteredBuses = [];
  Map<String, String> crowdPredictions = {};

  bool isLoading = false;
  bool showResults = false;
  String? error;
  String searchText = "";
  DateTime? lastFetched;

  Future<void> fetchBuses() async {
    setState(() {
      isLoading = true;
      error = null;
      showResults = false;
      crowdPredictions.clear();
    });

    try {
      final data = await HttpHelper.get("/getBusPositions");

      if (data == null || data['buses'] == null) {
        setState(() {
          error = "Failed to fetch live buses.";
          isLoading = false;
        });
        return;
      }

      allBuses = List<Map<String, dynamic>>.from(data['buses']);
      applySearchFilter();

      for (var bus in filteredBuses) {
        await predictCrowdForBus(bus);
      }

      setState(() {
        lastFetched = DateTime.now();
        showResults = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Error: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Future<void> predictCrowdForBus(Map<String, dynamic> bus) async {
    final now = DateTime.now();
    final hour = now.hour;

    String hourBand;
    if (hour >= 7 && hour < 9) hourBand = "07:00-09:00";
    else if (hour >= 9 && hour < 12) hourBand = "09:00-12:00";
    else if (hour >= 12 && hour < 15) hourBand = "12:00-15:00";
    else if (hour >= 15 && hour < 18) hourBand = "15:00-18:00";
    else hourBand = "Other";

    final payload = {
      "ROUTE": bus["trip_id"] ?? "",
      "TIMETABLE_HOUR_BAND": hourBand,
      "TRIP_POINT": "Start",
      "TIMETABLE_TIME": DateFormat.Hm().format(now),
      "ACTUAL_TIME": DateFormat.Hm().format(now),
    };

    final response = await HttpHelper.post("/predict-crowd", payload);
    final label = bus['label'] ?? '';

    setState(() {
      crowdPredictions[label] = response != null &&
              response["predicted_capacity_bucket_encoded"] != null
          ? _mapPredictionLabel(
              response["predicted_capacity_bucket_encoded"].toString())
          : "Unavailable";
    });
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

  void applySearchFilter() {
    if (searchText.isEmpty) {
      filteredBuses = [];
    } else {
      filteredBuses = allBuses
          .where((bus) =>
              bus["route_long"]?.toString().toLowerCase().contains(searchText.toLowerCase()) ??
              false)
          .toList();
    }
  }

  String getFreshness() {
    if (lastFetched == null) return "Unknown";
    final diff = DateTime.now().difference(lastFetched!).inSeconds;
    return diff < 60 ? "$diff seconds ago" : "${(diff ~/ 60)} min ago";
  }

  @override
  Widget build(BuildContext context) {
    final userName = user?.displayName ?? "Commuter";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Positions'),
        actions: [
          IconButton(onPressed: fetchBuses, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Hi, $userName!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: "Search by Destination or Route",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchText = value;
                setState(() {}); // For enabling/disabling button
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: searchText.trim().isEmpty ? null : fetchBuses,
                icon: const Icon(Icons.search),
                label: const Text("Search Buses"),
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading) const CircularProgressIndicator(),

            if (error != null) ...[
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],

            if (!showResults && !isLoading)
              const Expanded(
                child: Center(
                  child: Text(
                    "Enter a destination or route name above to find live buses with predictions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (showResults) ...[
              Text("${filteredBuses.length} buses found | Last updated: ${getFreshness()}",
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: FlutterMap(
                  options: MapOptions(
                    center: filteredBuses.isNotEmpty
                        ? LatLng(filteredBuses[0]['lat'], filteredBuses[0]['lon'])
                        : LatLng(-33.87, 151.21),
                    zoom: 12.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.crowdease',
                    ),
                    MarkerLayer(
                      markers: filteredBuses.map((bus) {
                        final lat = bus['lat'];
                        final lon = bus['lon'];
                        final label = bus['label'] ?? '';
                        final prediction = crowdPredictions[label] ?? '...';

                        return Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: "Bus $label\nCrowd: $prediction",
                            child: Icon(Icons.directions_bus_filled, size: 30, color: Colors.indigo),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = filteredBuses[index];
                    final label = bus['label'] ?? '';
                    final prediction = crowdPredictions[label] ?? '...';

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.directions_bus, color: Colors.indigo),
                        title: Text(
                          "Route ${bus['route_short'] ?? ''} – ${bus['route_long'] ?? ''}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text("Crowd: $prediction | Updated: ${bus['last_updated']}"),
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
