import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/route_data.dart';
import '../../crowd_feedback/feedback_dropdown_service.dart';
import '../../../config.dart';

class ForecastSearchScreen extends StatefulWidget {
  @override
  State<ForecastSearchScreen> createState() => _ForecastSearchScreenState();
}

class _ForecastSearchScreenState extends State<ForecastSearchScreen> {
  RouteData? selectedRoute;
  String? selectedDay;
  bool isLoading = false;
  List<FlSpot> graphSpots = [];

  List<RouteData> allRoutes = [];
  List<RouteData> filteredRoutes = [];

  final List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    try {
      final r = await FeedbackDropdownService.getRoutes();
      setState(() {
        allRoutes = r;
        filteredRoutes = r;
        selectedRoute ??= r.isNotEmpty ? r.first : null;
        selectedDay ??= weekdays.first;
      });
    } catch (e) {
      print("Failed to load routes: $e");
    }
  }

  Future<void> fetchForecast() async {
    if (selectedRoute == null || selectedDay == null) return;
    setState(() => isLoading = true);

    final uri = Uri.parse('${AppConfig.baseUrl}/forecast-daily').replace(queryParameters: {
      'route': selectedRoute!.routeId,
      'trip_point': 'Default',
      'day': selectedDay!,
    });

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final hourlyData = data['graph_data'] as List<dynamic>;

      setState(() {
        graphSpots = hourlyData.map<FlSpot>((entry) {
          final hour = double.parse(entry['hour'].split(":")[0]);
          final level = (entry['crowd_level'] as num).toDouble();
          return FlSpot(hour, level);
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to fetch forecast.");
    }
  }

  Widget buildGraph() {
    if (graphSpots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text(
          "No forecast data available.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 3,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: graphSpots,
              isCurved: true,
              barWidth: 2,
              color: Colors.cyan,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Text("Hour of Day"),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                getTitlesWidget: (value, _) {
                  final hour = value.toInt();
                  if (hour % 4 == 0) {
                    return Text('$hour:00', style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text("Crowding Level"),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Low', style: TextStyle(fontSize: 10));
                    case 1:
                      return const Text('Med', style: TextStyle(fontSize: 10));
                    case 2:
                      return const Text('High', style: TextStyle(fontSize: 10));
                    case 3:
                      return const Text('Full', style: TextStyle(fontSize: 10));
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forecast by Route & Day")),
      body: allRoutes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text("Select Route", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade500),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: "Search routes...",
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (query) {
                              setState(() {
                                filteredRoutes = allRoutes.where((r) =>
                                  r.shortName.toLowerCase().contains(query.toLowerCase()) ||
                                  r.longName.toLowerCase().contains(query.toLowerCase())
                                ).toList();
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SizedBox(
                          height: 160,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              itemCount: filteredRoutes.length,
                              itemBuilder: (context, index) {
                                final route = filteredRoutes[index];
                                return RadioListTile<RouteData>(
                                  dense: true,
                                  title: Text('${route.shortName} – ${route.longName}', style: const TextStyle(fontSize: 14)),
                                  value: route,
                                  groupValue: selectedRoute,
                                  onChanged: (val) => setState(() => selectedRoute = val),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField(
                    value: selectedDay,
                    decoration: const InputDecoration(labelText: 'Select Day of Week'),
                    items: weekdays.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (val) => setState(() => selectedDay = val as String),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchForecast,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Show Forecast"),
                  ),
                  const SizedBox(height: 24),
                  if (!isLoading) buildGraph(),
                ],
              ),
            ),
    );
  }
}
