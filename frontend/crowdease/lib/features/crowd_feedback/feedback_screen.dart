import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'feedback_model.dart';
import 'feedback_service.dart';
import 'feedback_dropdown_service.dart';
import '../../models/route_data.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  RouteData? selectedRoute;
  String? hourBand;
  String? tripPoint;
  String? timetableTime;
  String? actualTime;
  String capacity = 'MANY_SEATS_AVAILABLE';

  List<RouteData> allRoutes = [];
  List<RouteData> filteredRoutes = [];
  List<String> hourBands = [];
  List<String> allTripPoints = [];
  List<String> filteredTripPoints = [];

  final capacityMap = {
    'MANY_SEATS_AVAILABLE': 0,
    'FEW_SEATS_AVAILABLE': 1,
    'STANDING_ROOM_ONLY': 2,
    'CRUSH_CAPACITY': 3
  };

  @override
  void initState() {
    super.initState();
    loadDropdownData();
  }

  Future<void> loadDropdownData() async {
    try {
      final r = await FeedbackDropdownService.getRoutes();
      final h = await FeedbackDropdownService.getHourBands();
      final t = await FeedbackDropdownService.getTripPoints();

      setState(() {
        allRoutes = r;
        filteredRoutes = r;
        hourBands = h;
        allTripPoints = t;
        filteredTripPoints = t;
        selectedRoute ??= r.isNotEmpty ? r.first : null;
        hourBand ??= h.isNotEmpty ? h.first : null;
        tripPoint ??= t.isNotEmpty ? t.first : null;
      });
    } catch (e) {
      print("Error loading dropdown data: $e");
    }
  }

  Future<void> pickTime(Function(String) onSelected) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final time = TimeOfDay(hour: picked.hour, minute: picked.minute);
      final formatted = time.format(context);
      onSelected(formatted);
    }
  }

  Future<void> submit() async {
    if (_formKey.currentState!.validate() &&
        selectedRoute != null &&
        hourBand != null &&
        tripPoint != null) {
      final model = FeedbackModel(
        route: selectedRoute!.routeId,
        hourBand: hourBand!,
        tripPoint: tripPoint!,
        timetableTime: timetableTime!,
        actualTime: actualTime!,
        capacityBucket: capacity,
        capacityEncoded: capacityMap[capacity]!,
      );

      final success = await FeedbackService.submitFeedback(model);
      final snackBar = SnackBar(
        content: Text(success ? 'Feedback submitted successfully' : 'Submission failed'),
        backgroundColor: success ? Colors.green : Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: allRoutes.isEmpty || hourBands.isEmpty || allTripPoints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text("Route", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: hourBand,
                      items: hourBands.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => hourBand = v as String),
                      decoration: const InputDecoration(labelText: 'Hour Band'),
                      menuMaxHeight: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text("Trip Point", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                                hintText: "Search trip points...",
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: (query) {
                                setState(() {
                                  filteredTripPoints = allTripPoints.where((p) =>
                                    p.toLowerCase().contains(query.toLowerCase())
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
                                itemCount: filteredTripPoints.length,
                                itemBuilder: (context, index) {
                                  final point = filteredTripPoints[index];
                                  return RadioListTile<String>(
                                    dense: true,
                                    title: Text(point, style: const TextStyle(fontSize: 14)),
                                    value: point,
                                    groupValue: tripPoint,
                                    onChanged: (val) => setState(() => tripPoint = val),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Timetable Time'),
                      onTap: () => pickTime((val) => setState(() => timetableTime = val)),
                      validator: (v) => timetableTime == null ? 'Required' : null,
                      controller: TextEditingController(text: timetableTime),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Actual Time'),
                      onTap: () => pickTime((val) => setState(() => actualTime = val)),
                      validator: (v) => actualTime == null ? 'Required' : null,
                      controller: TextEditingController(text: actualTime),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: capacity,
                      items: capacityMap.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => capacity = v as String),
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      menuMaxHeight: 200,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submit,
                      child: const Text('Submit Feedback'),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
