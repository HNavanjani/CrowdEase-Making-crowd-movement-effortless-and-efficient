import 'package:flutter/material.dart';
import '../../bus/screens/live_bus_positions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Hub Overview (Destinations)')),
    const Center(child: Text('Alerts & Personalized Suggestions')),
    const Center(child: Text('Journey Planner (Directions)')),
    const Center(child: Text('More: Forecast, History, Help, etc.')),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showProfileMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 10, 100),
      items: const [
        PopupMenuItem(child: Text("Profile")),
        PopupMenuItem(child: Text("Logout")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrowdEase'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('CrowdEase Menu',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Destinations (Hub Overview)'),
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text('Directions (Journey Planner)'),
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {}, // to be added later
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Travel History & Insights'),
              onTap: () {}, // to be added later
            ),
            ListTile(
              leading: const Icon(Icons.notification_important),
              title: const Text('Alerts & Notifications'),
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Personalized Suggestions'),
              onTap: () {}, // to be added later
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('Simulated Forecast'),
              onTap: () {}, // to be added later
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Route Performance'),
              onTap: () {}, // to be added later
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('Live Bus Positions'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LiveBusPositions(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Help / About'),
              onTap: () {}, // to be added later
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
