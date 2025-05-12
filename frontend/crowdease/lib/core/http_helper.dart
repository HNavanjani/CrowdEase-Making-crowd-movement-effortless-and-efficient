import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class HttpHelper {
  static const Duration timeoutDuration = Duration(seconds: 15);

  static Future<dynamic> get(String endpoint) async {
    final fullUrl = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print("GET: $fullUrl");

    try {
      final response = await http.get(fullUrl).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("GET failed: ${response.statusCode}");
        return null;
      }
    } on SocketException {
      print("GET network error. Is Render waking up?");
      return null;
    } on TimeoutException {
      print("GET timeout. Render may be sleeping.");
      return null;
    } catch (e) {
      print("GET unexpected error: $e");
      return null;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final fullUrl = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print("POST: $fullUrl");

    try {
      final response = await http.post(
        fullUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.statusCode}");
        return null;
      }
    } on SocketException {
      print("POST network error.");
      return null;
    } on TimeoutException {
      print("POST timeout.");
      return null;
    } catch (e) {
      print("POST error: $e");
      return null;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final fullUrl = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print("PUT: $fullUrl");

    try {
      final response = await http.put(
        fullUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("PUT failed: ${response.statusCode}");
        return null;
      }
    } on SocketException {
      print("PUT network error.");
      return null;
    } on TimeoutException {
      print("PUT timeout.");
      return null;
    } catch (e) {
      print("PUT error: $e");
      return null;
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final fullUrl = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print("DELETE: $fullUrl");

    try {
      final response = await http.delete(fullUrl).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("DELETE failed: ${response.statusCode}");
        return null;
      }
    } on SocketException {
      print("DELETE network error.");
      return null;
    } on TimeoutException {
      print("DELETE timeout.");
      return null;
    } catch (e) {
      print("DELETE error: $e");
      return null;
    }
  }
}
