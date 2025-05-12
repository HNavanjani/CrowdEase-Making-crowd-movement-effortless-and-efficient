import '../../core/http_helper.dart';

class ApiService {
  static Future<List<Map<String, dynamic>>> getBusPositions() async {
    final data = await HttpHelper.get('/getBusPositions');

    if (data != null && data['buses'] != null) {
      print('Bus data received: ${data['buses'].length} buses');
      return List<Map<String, dynamic>>.from(data['buses']);
    } else {
      print('No bus data or server response error');
      return [];
    }
  }
}
