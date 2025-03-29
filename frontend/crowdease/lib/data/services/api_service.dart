import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';

class ApiService {
  static Future<List<Map<String, dynamic>>> getBusPositions() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/getBusPositions');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(decoded['buses']);
    } else {
      throw Exception('Failed to load bus data');
    }
  }
}
