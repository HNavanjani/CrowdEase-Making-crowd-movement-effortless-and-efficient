import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'faq_screen.dart';

class HelpAboutScreen extends StatefulWidget {
  const HelpAboutScreen({super.key});

  @override
  State<HelpAboutScreen> createState() => _HelpAboutScreenState();
}

class _HelpAboutScreenState extends State<HelpAboutScreen> {
  String appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = 'Version ${info.version}';
    });
  }

  Future<void> _handleEmailTap() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'crowdeaseofficial@gmail.com',
      query: Uri.encodeFull('subject=Support Request&body=Hi CrowdEase team,\n\nI need help with...'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Contact Support"),
          content: const Text("This would open your email app to contact crowdeaseofficial@gmail.com."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const Text(
          "We respect your privacy. No personal data is stored without your consent.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Contact Support"),
              subtitle: const Text("crowdeaseofficial@gmail.com"),
              onTap: _handleEmailTap,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy Policy"),
              onTap: _showPrivacyDialog,
            ),
            const Spacer(),
            Center(
              child: Text(
                "$appVersion\n© 2025 CrowdEase Team",
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
