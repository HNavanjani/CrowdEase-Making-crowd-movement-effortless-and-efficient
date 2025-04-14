import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bus/screens/live_bus_positions.dart';
import 'dummy_map_data.dart';

class CrowdMapAndPlannerScreen extends StatefulWidget {
  const CrowdMapAndPlannerScreen({super.key});

  @override
  State<CrowdMapAndPlannerScreen> createState() => _CrowdMapAndPlannerScreenState();
}

class _CrowdMapAndPlannerScreenState extends State<CrowdMapAndPlannerScreen> {
  String? fromStop;
  String? toStop;
  String? suggestionText;

  final user = FirebaseAuth.instance.currentUser;

  void findSuggestion() {
    if (fromStop != null && toStop != null) {
      setState(() {
        suggestionText =
            'Based on past trends, it’s best to travel from $fromStop to $toStop before 8 AM to avoid heavy crowd.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = user?.displayName ?? "Commuter";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Journey Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Greeting
            Text('Welcome, $userName!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Personal route card
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.alt_route, color: Colors.indigo),
                title: const Text('Your usual route: Redfern ➜ Town Hall'),
                subtitle: const Text('Best time: 8:00 AM'),
              ),
            ),

            const SizedBox(height: 24),

            const Text('Plan a New Journey',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // From dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(),
              ),
              items: busStops.map((stop) {
                return DropdownMenuItem(value: stop, child: Text(stop));
              }).toList(),
              onChanged: (value) => setState(() => fromStop = value),
            ),

            const SizedBox(height: 16),

            // To dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(),
              ),
              items: busStops.map((stop) {
                return DropdownMenuItem(value: stop, child: Text(stop));
              }).toList(),
              onChanged: (value) => setState(() => toStop = value),
            ),

            const SizedBox(height: 20),

            // Find best time button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: findSuggestion,
                icon: const Icon(Icons.schedule, color: Colors.white),
                label: const Text('Find Best Time', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Live bus check
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LiveBusPositions()),
                  );
                },
                icon: const Icon(Icons.directions_bus, color: Colors.indigo),
                label: const Text("Check Live Buses"),
              ),
            ),

            const SizedBox(height: 12),

            // Save plan (future feature)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                label: const Text("Save This Plan (Coming Soon)"),
              ),
            ),

            const SizedBox(height: 20),

            // Suggestion output
            if (suggestionText != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    suggestionText!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Smart tips
            const Text('Smart Travel Tips',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('• Avoid Route 333 after 5 PM on weekdays.'),
                    Text('• Route 370 is best before 8 AM.'),
                    Text('• Add 5–10 mins buffer for transfers.'),
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
