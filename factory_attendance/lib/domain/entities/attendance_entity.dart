class AttendanceEntity {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String type;
  final String status;
  final double distance;

  AttendanceEntity({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    required this.status,
    required this.distance,
  });
}
