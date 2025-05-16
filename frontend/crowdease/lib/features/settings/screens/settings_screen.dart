import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/screens/home_screen.dart';
import '../theme_controller.dart';

const appVersion = "1.0.0";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoLoadEnabled = true;
  bool compactLayout = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications') ?? true;
      darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      autoLoadEnabled = prefs.getBool('auto_load') ?? true;
      compactLayout = prefs.getBool('compact_layout') ?? false;
    });
  }

  void _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
            );
          },
        ),
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
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
                _savePreference('notifications', value);
                _showSnack(value ? "Notifications enabled" : "Notifications disabled");
              },
              title: const Text("Enable Notifications"),
              subtitle: const Text("Get real-time alerts and updates"),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: darkModeEnabled,
              onChanged: (value) async {
                setState(() => darkModeEnabled = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('dark_mode', value);

                ThemeController.themeNotifier.value =
                    value ? ThemeMode.dark : ThemeMode.light;

                _showSnack(value ? "Dark mode enabled" : "Dark mode disabled");
              },
              title: const Text("Dark Mode"),
              subtitle: const Text("Reduce eye strain in low light"),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: autoLoadEnabled,
              onChanged: (value) {
                setState(() => autoLoadEnabled = value);
                _savePreference('auto_load', value);
                _showSnack("Auto-load preference saved");
              },
              title: const Text("Auto-load Predictions"),
              subtitle: const Text("Fetch predictions automatically on launch"),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: compactLayout,
              onChanged: (value) {
                setState(() => compactLayout = value);
                _savePreference('compact_layout', value);
                _showSnack("Layout preference saved");
              },
              title: const Text("Use Compact Layout"),
              subtitle: const Text("Reduce padding and spacing for dense view"),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showSnack("Settings saved successfully");
            },
            icon: const Icon(Icons.save),
            label: const Text("Save Settings"),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Account",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.displayName ?? 'Logged in user'),
              subtitle: Text(user?.email ?? 'No email found'),
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
              subtitle: Text("Version $appVersion"),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language (Coming Soon)"),
              subtitle: const Text("Change app language"),
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }
}
