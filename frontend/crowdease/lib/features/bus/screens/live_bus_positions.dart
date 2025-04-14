import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/api_service.dart';

class LiveBusPositions extends StatefulWidget {
  const LiveBusPositions({super.key});

  @override
  State<LiveBusPositions> createState() => _LiveBusPositionsState();
}

class _LiveBusPositionsState extends State<LiveBusPositions> {
  List<Map<String, dynamic>> allBuses = [];
  List<Map<String, dynamic>> filteredBuses = [];
  Map<String, int> simulatedLoad = {};
  Timer? refreshTimer;
  bool isLoading = true;
  String? error;
  DateTime? lastFetched;

  String? selectedRoute;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchBuses();
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchBuses());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchBuses() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final rawData = await ApiService.getBusPositions();
      final filtered = rawData.where((bus) {
        final lat = bus['lat'] ?? 0.0;
        final lon = bus['lon'] ?? 0.0;
        return lat > -34.2 && lat < -33.5 && lon > 150.5 && lon < 151.5;
      }).toList();

      final rng = Random();
      simulatedLoad = {
        for (var bus in filtered) bus['label'] ?? '': rng.nextInt(20),
      };

      setState(() {
        allBuses = filtered;
        applyRouteFilter();
        isLoading = false;
        lastFetched = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void applyRouteFilter() {
    if (selectedRoute == null || selectedRoute == 'All') {
      filteredBuses = allBuses;
    } else {
      filteredBuses = allBuses.where((bus) {
        return getRouteFromTripId(bus["trip_id"]) == selectedRoute;
      }).toList();
    }
  }

  Color getColorForLoad(int load) {
    if (load >= 15) return Colors.red;
    if (load >= 8) return Colors.orange;
    return Colors.green;
  }

  String getDirectionText(num? bearing) {
    if (bearing == null) return "–";
    final angle = bearing % 360;
    if (angle >= 337.5 || angle < 22.5) return "North";
    if (angle >= 22.5 && angle < 67.5) return "North-East";
    if (angle >= 67.5 && angle < 112.5) return "East";
    if (angle >= 112.5 && angle < 157.5) return "South-East";
    if (angle >= 157.5 && angle < 202.5) return "South";
    if (angle >= 202.5 && angle < 247.5) return "South-West";
    if (angle >= 247.5 && angle < 292.5) return "West";
    return "North-West";
  }

  String getRouteFromTripId(String? tripId) {
    if (tripId == null || !tripId.contains('-')) return "–";
    final parts = tripId.split('-');
    return parts.length > 1 ? parts[1] : tripId;
  }

  String getFreshness() {
    if (lastFetched == null) return "Unknown";
    final diff = DateTime.now().difference(lastFetched!).inSeconds;
    if (diff < 60) return "$diff seconds ago";
    final mins = (diff / 60).round();
    return "$mins minute${mins > 1 ? 's' : ''} ago";
  }

  List<String> getAvailableRoutes() {
    final routes = allBuses.map((b) => getRouteFromTripId(b["trip_id"])).toSet().toList();
    routes.sort();
    return ['All', ...routes];
  }

  @override
  Widget build(BuildContext context) {
    final userName = user?.displayName ?? "Commuter";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Live Bus Positions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchBuses)
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Couldn’t load live bus data.\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.indigo.shade700, fontSize: 16)),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $userName!',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Filter by Route",
                              border: OutlineInputBorder(),
                            ),
                            value: selectedRoute ?? 'All',
                            items: getAvailableRoutes()
                                .map((route) => DropdownMenuItem(
                                    value: route, child: Text(route)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRoute = value;
                                applyRouteFilter();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${filteredBuses.length} active buses | Last updated: ${getFreshness()}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // MAP with colored markers
                    Expanded(
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
                              final label = bus['label'] ?? '';
                              final load = simulatedLoad[label] ?? 0;
                              final color = getColorForLoad(load);

                              return Marker(
                                point: LatLng(bus['lat'], bus['lon']),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text('Bus $label'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Route: ${getRouteFromTripId(bus["trip_id"])}'),
                                            Text('Heading: ${getDirectionText(bus["bearing"])}'),
                                            Text('Last Updated: ${bus["last_updated"] ?? "–"}'),
                                            Text('Simulated Load: $load'),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Close', style: TextStyle(color: Colors.indigo)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Icon(Icons.directions_bus_filled, size: 30, color: color),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // List View of Buses
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredBuses.length,
                        itemBuilder: (context, index) {
                          final bus = filteredBuses[index];
                          final label = bus['label'] ?? '';
                          final load = simulatedLoad[label] ?? 0;
                          final color = getColorForLoad(load);

                          return Card(
                            elevation: 3,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: color, width: 2),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: const Icon(Icons.directions_bus_filled, color: Colors.indigo),
                              ),
                              title: Text('Bus $label'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Route: ${getRouteFromTripId(bus["trip_id"])}'),
                                  Text('Heading: ${getDirectionText(bus["bearing"])}'),
                                  Text('Last Updated: ${bus["last_updated"] ?? "–"}'),
                                  Text('Simulated Load: $load passengers'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
