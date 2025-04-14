import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dummy_data.dart';

class HubOverviewScreen extends StatelessWidget {
  HubOverviewScreen({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final String userName = user?.displayName ?? "Commuter";
    final String userEmail = user?.email ?? "default@demo.com";
    final String suggestionText = personalizedTips[userEmail] ??
        'Avoid peak time routes between 5 PM – 6 PM for a better commute.';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Top: Greeting card
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.person_pin, color: Colors.indigo, size: 36),
                title: Text(
                  'Welcome, $userName!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Your regular route is: Route 890'),
              ),
            ),

            const SizedBox(height: 20),

            // Suggestion
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestionText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Route crowd levels
            const Text(
              'Current Route Crowd Levels:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            ...routeCrowdData.map((route) => Card(
              child: ListTile(
                leading: Icon(
                  route['icon'],
                  color: route['level'] == 'High' ? Colors.red :
                         route['level'] == 'Medium' ? Colors.orange :
                         Colors.green,
                ),
                title: Text(route['route']),
                subtitle: Text('Crowd: ${route['level']}'),
              ),
            )),

            const SizedBox(height: 24),

            // Navigation buttons (future screens)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/alerts'),
                  icon: const Icon(Icons.notifications, color: Colors.indigo),
                  label: const Text("See Alerts"),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/journey_planner'),
                  icon: const Icon(Icons.alt_route, color: Colors.indigo),
                  label: const Text("Plan Journey"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
