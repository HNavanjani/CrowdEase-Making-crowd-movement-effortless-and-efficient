import 'package:flutter/material.dart';

class PersonalizedSuggestionsScreen extends StatelessWidget {
  const PersonalizedSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> suggestions = [
      {
        "title": "Best time to travel",
        "message": "Try leaving before 7:30 AM to avoid the morning rush on Route 001.",
        "icon": Icons.access_time,
        "color": Colors.blue
      },
      {
        "title": "Less crowded route",
        "message": "Route 021 is usually less crowded between 5–6 PM.",
        "icon": Icons.traffic,
        "color": Colors.green
      },
      {
        "title": "Smart travel tip",
        "message": "Traveling midweek (Tue–Thu) often has the lowest crowd levels.",
        "icon": Icons.lightbulb,
        "color": Colors.orange
      },
      {
        "title": "Night travel alert",
        "message": "After 8 PM, service frequency drops. Plan accordingly.",
        "icon": Icons.nightlight_round,
        "color": Colors.deepPurple
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personalized Suggestions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Tailored for You",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...suggestions.map((s) => Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: s["color"] as Color,
                          child: Icon(s["icon"] as IconData, color: Colors.white),
                        ),
                        title: Text(
                          s["title"] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(s["message"] as String),
                      ),
                    )),
                const SizedBox(height: 20),
                Card(
                  color: Colors.indigo.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Summary Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Most used route: 001"),
                        Text("Least crowded time: 11 AM – 1 PM"),
                        Text("Busiest day: Friday"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Suggestions refreshed")),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Suggestions"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
