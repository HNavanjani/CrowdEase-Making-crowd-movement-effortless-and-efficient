// travel_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/route_data.dart';
import '../../../core/http_helper.dart';

class TravelHistoryScreen extends StatefulWidget {
  final String userId;
  const TravelHistoryScreen({super.key, required this.userId});

  @override
  State<TravelHistoryScreen> createState() => _TravelHistoryScreenState();
}

class _TravelHistoryScreenState extends State<TravelHistoryScreen> {
  List<Map<String, dynamic>> travelHistory = [];
  Map<String, String> routeLabels = {};
  bool isLoading = true;

  RouteData? selectedRoute;
  String selectedCrowd = 'MANY_SEATS_AVAILABLE';
  DateTime? selectedDate;
  List<RouteData> allRoutes = [];
  List<RouteData> filteredRoutes = [];
  String selectedRange = '7';

  final capacityMap = {
    'MANY_SEATS_AVAILABLE': 'Many Seats',
    'FEW_SEATS_AVAILABLE': 'Few Seats',
    'STANDING_ROOM_ONLY': 'Standing Room Only',
    'CRUSH_CAPACITY': 'Full',
  };

  final capacityColors = {
    'Many Seats': Colors.green,
    'Few Seats': Colors.orange,
    'Standing Room Only': Colors.red,
    'Full': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    loadRoutesAndHistory();
  }

  Future<void> loadRoutesAndHistory() async {
    final routeList = await HttpHelper.get("/dropdown/routes");
    final history = await HttpHelper.get("/travel-history/${widget.userId}");

    if (routeList != null) {
      for (final route in routeList) {
        routeLabels[route['route_id']] =
            "${route['route_short_name']} – ${route['route_long_name']}";
      }
      allRoutes =
          routeList.map<RouteData>((r) => RouteData.fromJson(r)).toList();
      filteredRoutes = allRoutes;
    }

    if (history != null) {
      travelHistory = List<Map<String, dynamic>>.from(history);
    }

    setState(() => isLoading = false);
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> submitJourney() async {
    if (selectedRoute == null || selectedDate == null) return;
    final body = {
      "user_id": widget.userId,
      "route": selectedRoute!.routeId,
      "date": DateFormat('yyyy-MM-dd').format(selectedDate!),
      "crowd_level": capacityMap[selectedCrowd] ?? 'Many Seats',
    };

    final res = await HttpHelper.post("/travel-history", body);
    if (res != null &&(res['message'] != null || res.toString().contains('success'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Journey added successfully"),
          backgroundColor: Colors.green,
        ),
      );
      selectedRoute = null;
      selectedDate = null;
      selectedCrowd = 'MANY_SEATS_AVAILABLE';
      await loadRoutesAndHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit journey"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, int> getCrowdCounts() {
    final counts = {
      'Many Seats': 0,
      'Few Seats': 0,
      'Standing Room Only': 0,
      'Full': 0,
    };
    for (var entry in travelHistory) {
      final level = entry['crowd_level'];
      if (counts.containsKey(level)) {
        counts[level] = (counts[level] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, Map<String, int>> getCrowdByDay() {
    final now = DateTime.now();
    final rangeLimit =
        selectedRange == 'all'
            ? DateTime(2000)
            : now.subtract(Duration(days: int.parse(selectedRange)));

    final result = <String, Map<String, int>>{};
    for (var entry in travelHistory) {
      final dateStr = entry['date'] ?? '';
      final dt = DateTime.tryParse(dateStr);
      if (dt == null || dt.isBefore(rangeLimit)) continue;
      final day = DateFormat.E().format(dt);
      final level = entry['crowd_level'];
      result.putIfAbsent(
        day,
        () => {
          'Many Seats': 0,
          'Few Seats': 0,
          'Standing Room Only': 0,
          'Full': 0,
        },
      );
      result[day]![level] = (result[day]![level] ?? 0) + 1;
    }
    return result;
  }

  Map<String, int> getTopRoutes() {
    final counts = <String, int>{};
    for (var entry in travelHistory) {
      final route = entry['route'];
      counts[route] = (counts[route] ?? 0) + 1;
    }
    return counts;
  }

  BarChartGroupData buildGroupedBar(String day, Map<String, int> data, int x) {
    final levels = ["Many Seats", "Few Seats", "Standing Room Only", "Full"];
    return BarChartGroupData(
      x: x,
      barRods: List.generate(
        4,
        (i) => BarChartRodData(
          toY: (data[levels[i]] ?? 0).toDouble(),
          width: 8,
          color: capacityColors[levels[i]]!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crowdCounts = getCrowdCounts();
    final crowdByDay = getCrowdByDay();
    final topRoutes = getTopRoutes();
    final sortedDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      appBar: AppBar(title: const Text("Travel History & Insights")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Crowd Level Distribution",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Based on all journeys recorded",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections:
                              crowdCounts.entries
                                  .map(
                                    (e) => PieChartSectionData(
                                      value: e.value.toDouble(),
                                      color: capacityColors[e.key],
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      children:
                          capacityColors.entries
                              .map(
                                (e) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: e.value,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      e.key,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Crowd Level by Day",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton(
                          value: selectedRange,
                          items: const [
                            DropdownMenuItem(
                              value: '7',
                              child: Text("Last 7 Days"),
                            ),
                            DropdownMenuItem(
                              value: '30',
                              child: Text("Last 30 Days"),
                            ),
                            DropdownMenuItem(
                              value: 'all',
                              child: Text("All Time"),
                            ),
                          ],
                          onChanged:
                              (v) =>
                                  setState(() => selectedRange = v as String),
                        ),
                      ],
                    ),
                    const Text(
                      "Each bar shows crowd level counts by weekday",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  return Text(
                                    sortedDays[value.toInt() % 7],
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 != 0)
                                    return const SizedBox.shrink();
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: List.generate(sortedDays.length, (i) {
                            final day = sortedDays[i];
                            return buildGroupedBar(
                              day,
                              crowdByDay[day] ?? {},
                              i,
                            );
                          }),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: true),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Top 5 Routes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(() {
                      final sorted = topRoutes.entries.toList();
                      sorted.sort((a, b) => b.value.compareTo(a.value));
                      return sorted
                          .take(5)
                          .map(
                            (e) => ListTile(
                              title: Text(routeLabels[e.key] ?? e.key),
                              trailing: Text("${e.value} times"),
                            ),
                          );
                    })(),

                    const Divider(height: 32),
                    const Text(
                      "Add Journey (Manual Entry)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade600),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Search routes...",
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                              onChanged: (query) {
                                setState(() {
                                  filteredRoutes =
                                      allRoutes
                                          .where(
                                            (r) =>
                                                r.shortName
                                                    .toLowerCase()
                                                    .contains(
                                                      query.toLowerCase(),
                                                    ) ||
                                                r.longName
                                                    .toLowerCase()
                                                    .contains(
                                                      query.toLowerCase(),
                                                    ),
                                          )
                                          .toList();
                                });
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              itemCount: filteredRoutes.length,
                              itemBuilder: (context, index) {
                                final route = filteredRoutes[index];
                                return RadioListTile<RouteData>(
                                  dense: true,
                                  title: Text(
                                    "${route.shortName} – ${route.longName}",
                                  ),
                                  value: route,
                                  groupValue: selectedRoute,
                                  onChanged:
                                      (val) =>
                                          setState(() => selectedRoute = val),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: pickDate,
                      child: Text(
                        selectedDate == null
                            ? "Pick Date"
                            : DateFormat('yyyy-MM-dd').format(selectedDate!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: selectedCrowd,
                      items:
                          capacityMap.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => selectedCrowd = v!),
                      decoration: const InputDecoration(
                        labelText: 'Crowd Level',
                      ),
                      menuMaxHeight: 200,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: submitJourney,
                      icon: const Icon(Icons.send),
                      label: const Text("Submit Journey"),
                    ),
                  ],
                ),
              ),
    );
  }
}
