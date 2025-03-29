import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class LiveBusPositions extends StatelessWidget {
  const LiveBusPositions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Bus Positions')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getBusPositions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final buses = snapshot.data!;
          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              return ListTile(
                title: Text('Bus ${bus["label"]}'),
                subtitle: Text('Lat: ${bus["lat"]}, Lon: ${bus["lon"]}'),
              );
            },
          );
        },
      ),
    );
  }
}
