import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/route_data.dart';
import '../../../core/http_helper.dart';

class CrowdMapAndPlannerScreen extends StatefulWidget {
  const CrowdMapAndPlannerScreen({super.key});

  @override
  State<CrowdMapAndPlannerScreen> createState() => _CrowdMapAndPlannerScreenState();
}

class _CrowdMapAndPlannerScreenState extends State<CrowdMapAndPlannerScreen> {
  final user = FirebaseAuth.instance.currentUser;

  List<RouteData> structuredRoutes = [];
  List<String> fromStops = [];
  List<String> toStops = [];
  String? fromStop;
  String? toStop;
  TimeOfDay? selectedTime;
  String? suggestionText;
  String predictionText = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    final data = await HttpHelper.get('/dropdown/routes');
    if (data != null) {
      final routes = (data as List).map((e) => RouteData.fromJson(e)).toList();
      final allStops = routes
          .expand((r) => r.longName.split("➜"))
          .map((s) => s.trim())
          .toSet()
          .toList();

      setState(() {
        structuredRoutes = routes;
        fromStops = allStops;
        toStops = allStops;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
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
      case "0": return "Low";
      case "1": return "Medium";
      case "2": return "High";
      case "3": return "Full";
      default: return "Unavailable";
    }
  }

  Color _getColorForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'full':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> checkCrowdLevel() async {
    if (fromStop == null || toStop == null || selectedTime == null) return;

    final timeStr = selectedTime!.hour.toString().padLeft(2, '0') +
        ':' +
        selectedTime!.minute.toString().padLeft(2, '0');
    final hourBand = _getHourBand(timeStr);

    final payload = {
      "ROUTE": "$fromStop ➜ $toStop",
      "TIMETABLE_HOUR_BAND": hourBand,
      "TRIP_POINT": "Start",
      "TIMETABLE_TIME": timeStr,
      "ACTUAL_TIME": timeStr,
    };

    final res = await HttpHelper.post("/predict-crowd", payload);

    if (res != null) {
      final code = res["predicted_capacity_bucket_encoded"]?.toString() ?? "Unavailable";
      final label = _mapPredictionLabel(code);

      setState(() {
        predictionText = label;
        suggestionText =
            "Crowd prediction for $fromStop ➜ $toStop at $timeStr: $label.";
      });
    } else {
      setState(() {
        predictionText = "Unavailable";
        suggestionText = "Could not get prediction. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = user?.displayName ?? "Commuter";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Journey Planner')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $userName!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                  const SizedBox(height: 10),

                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const ListTile(
                      leading: Icon(Icons.route, color: Colors.indigo),
                      title: Text('Plan your journey'),
                      subtitle: Text('Get predicted crowd levels'),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SearchSelectField(
                    label: 'From Stop',
                    items: fromStops,
                    selected: fromStop,
                    onSelected: (val) => setState(() => fromStop = val),
                  ),

                  const SizedBox(height: 16),
                  SearchSelectField(
                    label: 'To Stop',
                    items: toStops,
                    selected: toStop,
                    onSelected: (val) => setState(() => toStop = val),
                  ),

                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime != null
                        ? 'Selected Time: ${selectedTime!.format(context)}'
                        : 'Pick Travel Time'),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: checkCrowdLevel,
                      icon: const Icon(Icons.analytics, color: Colors.white),
                      label: const Text('Check Crowd Level',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  if (suggestionText != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.directions_bus_filled, color: Colors.indigo, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Crowd prediction for $fromStop ➜ $toStop at ${selectedTime!.format(context)}:",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text("Crowd Level: ", style: TextStyle(fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getColorForLabel(predictionText),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          predictionText,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// Reusable search-select modal field
class SearchSelectField extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;

  const SearchSelectField({
    required this.label,
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  _SearchSelectFieldState createState() => _SearchSelectFieldState();
}

class _SearchSelectFieldState extends State<SearchSelectField> {
  List<String> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = widget.items;
  }

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16, right: 16, top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.label.toLowerCase()}…',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (q) {
                    setInner(() {
                      filtered = widget.items
                          .where((s) =>
                              s.toLowerCase().contains(q.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: filtered.isEmpty
                      ? const Center(child: Text('No matches'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => ListTile(
                            title: Text(filtered[i]),
                            onTap: () {
                              widget.onSelected(filtered[i]);
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.selected ?? 'Select ${widget.label}';
    return GestureDetector(
      onTap: _openSheet,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(display),
      ),
    );
  }
}
