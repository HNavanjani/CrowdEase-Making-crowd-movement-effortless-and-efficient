import 'package:flutter/material.dart';

class TravelHistoryScreen extends StatelessWidget {
  const TravelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyHistory = [
      {"route": "001", "date": "2025-04-18", "crowd": "Few Seats"},
      {"route": "010", "date": "2025-04-17", "crowd": "Standing Room Only"},
      {"route": "021", "date": "2025-04-16", "crowd": "Many Seats"},
    ];

    Color getCrowdColor(String crowd) {
      switch (crowd) {
        case "Many Seats":
          return Colors.green.shade600;
        case "Few Seats":
          return Colors.orange.shade600;
        case "Standing Room Only":
          return Colors.red.shade600;
        default:
          return Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel History & Insights"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Journeys",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...dummyHistory.map((trip) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.indigo, size: 30),
                  title: Text("Route ${trip['route']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  subtitle: Text("Date: ${trip['date']}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: getCrowdColor(trip['crowd']!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip['crowd']!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Divider(thickness: 1.2),
            const SizedBox(height: 16),
            const Text(
              "Weekly Summary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.route, color: Colors.deepPurple),
                  title: Text("Most used route"),
                  subtitle: Text("001"),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: Colors.teal),
                  title: Text("Busiest day"),
                  subtitle: Text("Friday"),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.chair_alt, color: Colors.green),
                  title: Text("Least crowded route"),
                  subtitle: Text("021"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
