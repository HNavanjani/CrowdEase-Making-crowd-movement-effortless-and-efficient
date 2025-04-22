import 'package:flutter/material.dart';

class AlertsAndNotificationsScreen extends StatelessWidget {
  const AlertsAndNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        "icon": Icons.warning_amber_rounded,
        "color": Colors.redAccent,
        "text": "Route 010 will be delayed due to maintenance.",
        "time": "Today • 7:30 AM"
      },
      {
        "icon": Icons.groups_2_rounded,
        "color": Colors.orange,
        "text": "Expect heavy crowding on Route 003 between 5–6 PM.",
        "time": "Today • 6:00 AM"
      },
      {
        "icon": Icons.refresh_rounded,
        "color": Colors.green,
        "text": "Crowd predictions have been updated for your favorites.",
        "time": "Yesterday • 9:45 PM"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts & Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Recent Alerts",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) => Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: alert["color"] as Color,
                    child: Icon(alert["icon"] as IconData, color: Colors.white),
                  ),
                  title: Text(alert["text"] as String),
                  subtitle: Text(alert["time"] as String),
                ),
              )),
          const SizedBox(height: 24),
          const Text(
            "Notification Settings",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile("Service Disruptions", true),
          _buildSwitchTile("Crowd Alerts", true),
          _buildSwitchTile("Prediction Updates", true),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: (v) {},
        title: Text(title),
        activeColor: Colors.indigo,
      ),
    );
  }
}
