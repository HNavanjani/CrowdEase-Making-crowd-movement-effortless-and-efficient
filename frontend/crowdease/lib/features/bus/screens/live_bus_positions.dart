import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/services/api_service.dart';

class LiveBusPositions extends StatefulWidget {
  const LiveBusPositions({super.key});

  @override
  State<LiveBusPositions> createState() => _LiveBusPositionsState();
}

class _LiveBusPositionsState extends State<LiveBusPositions> {
  List<Map<String, dynamic>> buses = [];
  Timer? refreshTimer;
  bool isLoading = true;
  String? error;
  DateTime? lastFetched;

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

      setState(() {
        buses = filtered;
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

  String getDirectionText(num? bearing) {
    if (bearing == null) return "Unknown";
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
    if (tripId == null || !tripId.contains('-')) return "N/A";
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

  String getActivityLevel(int count) {
    if (count >= 15) return "Heavy Traffic";
    if (count >= 8) return "Moderate Traffic";
    if (count >= 1) return "Light Traffic";
    return "No Activity";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Bus Positions')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Couldn’t load live bus data.\n$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                    ),
                  ),
                )
              : buses.isEmpty
                  ? const Center(
                      child: Text(
                        'No active Sydney buses found at the moment.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.indigo.shade50,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getActivityLevel(buses.length),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${buses.length} buses in Sydney | Last updated: ${getFreshness()}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FlutterMap(
                            options: MapOptions(
                              center: LatLng(buses[0]['lat'], buses[0]['lon']),
                              zoom: 12.5,
                              onTap: (_, __) => Navigator.pop(context),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.crowdease',
                              ),
                              MarkerLayer(
                                markers: buses.map((bus) {
                                  return Marker(
                                    point: LatLng(bus['lat'], bus['lon']),
                                    width: 40,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Bus ${bus["label"] ?? "Unknown"}'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Route: ${getRouteFromTripId(bus["trip_id"])}'),
                                                Text('Heading: ${getDirectionText(bus["bearing"])}'),
                                                Text('Last Updated: ${bus["last_updated"] ?? "N/A"}'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.directions_bus_filled,
                                        color: Colors.indigo,
                                        size: 30,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          flex: 1,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: buses.length,
                            itemBuilder: (context, index) {
                              final bus = buses[index];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    child: const Icon(Icons.directions_bus_filled, color: Colors.indigo),
                                  ),
                                  title: Text('Bus ${bus["label"] ?? "Unknown"}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Route: ${getRouteFromTripId(bus["trip_id"])}'),
                                      Text('Heading: ${getDirectionText(bus["bearing"])}'),
                                      Text('Last Updated: ${bus["last_updated"] ?? "N/A"}'),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.wifi, color: Colors.green),
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
