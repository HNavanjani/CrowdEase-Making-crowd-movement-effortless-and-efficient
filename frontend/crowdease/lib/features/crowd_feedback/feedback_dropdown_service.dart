import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

class FeedbackDropdownService {
  static Future<List<String>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/available-routes'));
    final data = jsonDecode(response.body);
    return List<String>.from(data['routes']);
  }

  static Future<List<String>> getHourBands() async {
    final response = await http.get(Uri.parse('$baseUrl/available-hour-bands'));
    final data = jsonDecode(response.body);
    return List<String>.from(data['hour_bands']);
  }

  static Future<List<String>> getTripPoints() async {
    final response = await http.get(Uri.parse('$baseUrl/available-trip-points'));
    final data = jsonDecode(response.body);
    return List<String>.from(data['trip_points']);
  }
}
