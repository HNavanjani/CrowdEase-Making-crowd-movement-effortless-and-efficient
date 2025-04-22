import 'package:flutter/material.dart';

class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help / About'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "About CrowdEase",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "CrowdEase is your smart travel companion designed to make public transport more efficient. "
              "It predicts crowd levels, suggests better times to travel, and helps you plan your commute with confidence.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              "Need Help?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("Frequently Asked Questions"),
              onTap: () {
                // TODO: Navigate to FAQ page
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Contact Support"),
              subtitle: const Text("crowdeaseofficial@gmail.com"),
              onTap: () {
                
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy Policy"),
              onTap: () {
                // TODO: Link to Privacy Policy
              },
            ),
            const Spacer(),
            Center(
              child: Text(
                "Version 1.0.0\n© 2025 CrowdEase Team",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
