import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool notificationsEnabled = true;
    bool darkModeEnabled = false;
    bool autoLoadEnabled = true;
    bool compactLayout = false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "General",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              value: notificationsEnabled,
              onChanged: (value) {},
              title: const Text("Enable Notifications"),
              subtitle: const Text("Get real-time alerts and updates"),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: darkModeEnabled,
              onChanged: (value) {},
              title: const Text("Dark Mode"),
              subtitle: const Text("Reduce eye strain in low light"),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: autoLoadEnabled,
              onChanged: (value) {},
              title: const Text("Auto-load Predictions"),
              subtitle: const Text("Fetch predictions automatically on launch"),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: compactLayout,
              onChanged: (value) {},
              title: const Text("Use Compact Layout"),
              subtitle: const Text("Reduce padding and spacing for dense view"),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Account",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Privacy & Security"),
              subtitle: const Text("Manage your data and preferences"),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("Help & Support"),
              subtitle: const Text("FAQs and contact options"),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About CrowdEase"),
              subtitle: const Text("Version 1.0.0"),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
