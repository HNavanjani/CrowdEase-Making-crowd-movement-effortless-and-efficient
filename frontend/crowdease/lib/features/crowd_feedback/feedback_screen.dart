import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'feedback_model.dart';
import 'feedback_service.dart';
import 'feedback_dropdown_service.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  String? route;
  String? hourBand;
  String? tripPoint;
  String? timetableTime;
  String? actualTime;
  String capacity = 'MANY_SEATS_AVAILABLE';

  List<String> routes = [];
  List<String> hourBands = [];
  List<String> tripPoints = [];

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
        routes = r;
        hourBands = h;
        tripPoints = t;
        route ??= routes.isNotEmpty ? routes.first : null;
        hourBand ??= hourBands.isNotEmpty ? hourBands.first : null;
        tripPoint ??= tripPoints.isNotEmpty ? tripPoints.first : null;
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
        route != null &&
        hourBand != null &&
        tripPoint != null) {
      final model = FeedbackModel(
        route: route!,
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
      body: routes.isEmpty || hourBands.isEmpty || tripPoints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField(
                      value: route,
                      items: routes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => route = v as String),
                      decoration: const InputDecoration(labelText: 'Route'),
                      menuMaxHeight: 200,
                    ),
                    DropdownButtonFormField(
                      value: hourBand,
                      items: hourBands.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => hourBand = v as String),
                      decoration: const InputDecoration(labelText: 'Hour Band'),
                      menuMaxHeight: 200,
                    ),
                    DropdownButtonFormField(
                      value: tripPoint,
                      items: tripPoints.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => tripPoint = v as String),
                      decoration: const InputDecoration(labelText: 'Trip Point'),
                      menuMaxHeight: 200,
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Timetable Time'),
                      onTap: () => pickTime((val) => setState(() => timetableTime = val)),
                      validator: (v) => timetableTime == null ? 'Required' : null,
                      controller: TextEditingController(text: timetableTime),
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Actual Time'),
                      onTap: () => pickTime((val) => setState(() => actualTime = val)),
                      validator: (v) => actualTime == null ? 'Required' : null,
                      controller: TextEditingController(text: actualTime),
                    ),
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
