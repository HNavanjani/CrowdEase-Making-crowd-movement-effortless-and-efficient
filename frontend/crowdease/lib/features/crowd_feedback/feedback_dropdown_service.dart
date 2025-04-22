import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

class FeedbackDropdownService {
  static Future<List<String>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/dropdown/routes'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data); // no key like 'routes'
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
