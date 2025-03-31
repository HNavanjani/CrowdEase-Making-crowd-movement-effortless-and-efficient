import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';

class ApiService {
  static Future<List<Map<String, dynamic>>> getBusPositions() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/getBusPositions');

    try {
      final response = await http.get(url);
      print('API CALL: $url');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('Bus data received: ${decoded['buses']?.length ?? 0} buses');
        return List<Map<String, dynamic>>.from(decoded['buses']);
      } else {
        print('Failed to load bus data');
        print('Response body: ${response.body}');
        throw Exception('Failed to load bus data');
      }
    } catch (e) {
      print('Exception during API call: $e');
      rethrow;
    }
  }
}
