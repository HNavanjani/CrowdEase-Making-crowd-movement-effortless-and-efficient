class FeedbackModel {
  final String route;
  final String hourBand;
  final String tripPoint;
  final String timetableTime;
  final String actualTime;
  final String capacityBucket;
  final int capacityEncoded;

  FeedbackModel({
    required this.route,
    required this.hourBand,
    required this.tripPoint,
    required this.timetableTime,
    required this.actualTime,
    required this.capacityBucket,
    required this.capacityEncoded,
  });

  Map<String, dynamic> toJson() => {
        'ROUTE': route,
        'TIMETABLE_HOUR_BAND': hourBand,
        'TRIP_POINT': tripPoint,
        'TIMETABLE_TIME': timetableTime,
        'ACTUAL_TIME': actualTime,
        'CAPACITY_BUCKET': capacityBucket,
        'CAPACITY_BUCKET_ENCODED': capacityEncoded,
      };
}
