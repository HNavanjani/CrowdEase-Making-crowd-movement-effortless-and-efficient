import 'package:flutter/material.dart';

class RoutePerformanceScreen extends StatelessWidget {
  const RoutePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeStats = [
      {
        "route": "001",
        "onTime": 95,
        "crowdLevel": "Low",
        "delayTrend": "↓"
      },
      {
        "route": "010",
        "onTime": 80,
        "crowdLevel": "Medium",
        "delayTrend": "→"
      },
      {
        "route": "021",
        "onTime": 65,
        "crowdLevel": "High",
        "delayTrend": "↑"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Performance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Route Stats",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: routeStats.length,
                itemBuilder: (context, index) {
                  final route = routeStats[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Route ${route["route"]}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.green),
                              const SizedBox(width: 8),
                              Text("On-Time Rate: ${route["onTime"]}%"),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.people, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text("Crowd Level: ${route["crowdLevel"]}"),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text("Delay Trend: ${route["delayTrend"]}"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "📌 Tip: Use high on-time routes for time-sensitive travel.",
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          ],
        ),
      ),
    );
  }
}
