import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models/route_data.dart';

class FeedbackDropdownService {
  static Future<List<RouteData>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/dropdown/routes'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => RouteData.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<String>> getHourBands() async {
    final response = await http.get(Uri.parse('$baseUrl/dropdown/hour_bands'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data);
    }
    return [];
  }

  static Future<List<String>> getTripPoints() async {
    final response = await http.get(Uri.parse('$baseUrl/dropdown/trip_points'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data);
    }
    return [];
  }
}
