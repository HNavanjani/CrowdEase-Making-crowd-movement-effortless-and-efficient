import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/http_helper.dart';

class SimulatedForecastScreen extends StatefulWidget {
  const SimulatedForecastScreen({super.key});

  @override
  State<SimulatedForecastScreen> createState() => _SimulatedForecastScreenState();
}

class _SimulatedForecastScreenState extends State<SimulatedForecastScreen> {
  Map<String, dynamic> timeBandData = {};
  Map<String, dynamic> weeklyData = {};
  bool isLoading = true;

  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final List<String> hourLabels = List.generate(24, (i) => i.toString().padLeft(2, '0') + ":00");

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await HttpHelper.get('/forecast/weekly');
    if (response != null && response['time_band_forecast'] != null) {
      setState(() {
        timeBandData = Map<String, dynamic>.from(response['time_band_forecast']);
        weeklyData = Map<String, dynamic>.from(response['weekly_forecast']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  String getCrowdingLevelText(num value) {
    if (value >= 0.1) return 'High';
    if (value >= 0.07) return 'Moderate';
    return 'Low';
  }

  Widget buildWeeklySummary() {
    final sorted = weeklyData.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final peakDay = sorted.first;
    final quietDay = sorted.last;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📊 Weekly Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("• ${peakDay.key} has the highest crowding: ${getCrowdingLevelText(peakDay.value)}"),
            Text("• ${quietDay.key} is the least crowded: ${getCrowdingLevelText(quietDay.value)}"),
            const SizedBox(height: 6),
            const Text("• Consider traveling mid-week or during low periods for a better experience."),
          ],
        ),
      ),
    );
  }

  Widget buildLineChart() {
    List<LineChartBarData> lines = [];

    for (var day in days) {
      final band = Map<String, dynamic>.from(timeBandData[day] ?? {});
      final entries = hourLabels.map((hour) {
        final nextHour = int.parse(hour.split(":")[0]) + 1;
        final label = "$hour to ${nextHour.toString().padLeft(2, '0')}:00";
        return (band[label] as num?)?.toDouble() ?? 0.0;
      }).toList();

      lines.add(
        LineChartBarData(
          spots: List.generate(entries.length, (i) => FlSpot(i.toDouble(), entries[i])),
          isCurved: true,
          color: Colors.cyan,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text("📈 Hourly Trends (All Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineBarsData: lines,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Hour of Day"),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (value, _) => Text(hourLabels[value.toInt() % 24], style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Crowding Level"),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.05,
                      getTitlesWidget: (value, _) => Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDailyCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: days.map((day) {
        final band = Map<String, dynamic>.from(timeBandData[day] ?? {});
        if (band.isEmpty) return const SizedBox();

        final sorted = band.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));
        final peak = sorted.first;
        final quiet = sorted.last;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              // Text("Busiest: ${peak.key} → ${peak.value}"),
              // Text("Quietest: ${quiet.key} → ${quiet.value}"),
              Text("Busiest: ${peak.key}"),
              Text("Quietest: ${quiet.key}"),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crowd Forecast Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildWeeklySummary(),
                  const SizedBox(height: 16),
                  buildLineChart(),
                  const SizedBox(height: 16),
                  const Text("Daily Peak & Quiet Hours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  buildDailyCards(),
                ],
              ),
            ),
    );
  }
}
