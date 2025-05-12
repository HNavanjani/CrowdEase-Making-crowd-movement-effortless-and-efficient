import '../../models/route_data.dart';
import '../../core/http_helper.dart';

class FeedbackDropdownService {
  static Future<List<RouteData>> getRoutes() async {
    final data = await HttpHelper.get('/dropdown/routes');
    if (data != null) {
      return data.map<RouteData>((json) => RouteData.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<String>> getHourBands() async {
    final data = await HttpHelper.get('/dropdown/hour_bands');
    if (data != null) {
      return List<String>.from(data);
    }
    return [];
  }

  static Future<List<String>> getTripPoints() async {
    final data = await HttpHelper.get('/dropdown/trip_points');
    if (data != null) {
      return List<String>.from(data);
    }
    return [];
  }
}
