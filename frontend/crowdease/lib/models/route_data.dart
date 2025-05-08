class RouteData {
  final String routeId;
  final String shortName;
  final String longName;
  final String desc;

  RouteData({
    required this.routeId,
    required this.shortName,
    required this.longName,
    required this.desc,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      routeId: json['route_id'],
      shortName: json['route_short_name'] ?? '',
      longName: json['route_long_name'] ?? '',
      desc: json['route_desc'] ?? '',
    );
  }

  @override
  String toString() => '$shortName - $longName'; 
}
