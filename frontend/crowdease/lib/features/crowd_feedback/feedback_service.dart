import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'feedback_model.dart';
import '../../core/api_constants.dart';

class FeedbackService {
  static Future<bool> submitFeedback(FeedbackModel model) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/submit-feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    return response.statusCode == 200;
  }
}
