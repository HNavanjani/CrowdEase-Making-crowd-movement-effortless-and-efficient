import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'feedback_model.dart';

class FeedbackService {
  static Future<bool> submitFeedback(FeedbackModel model) async {
    final response = await http.post(
      Uri.parse('$baseUrl/submit-feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    return response.statusCode == 200;
  }
}
