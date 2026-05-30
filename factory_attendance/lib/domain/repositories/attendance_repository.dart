import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  Future<void> checkIn({
    required String userId, 
    required double distance, 
    required String status, 
    required double latitude, 
    required double longitude
  });
  
  Future<void> checkOut({
    required String userId, 
    required double distance, 
    required String status, 
    required double latitude, 
    required double longitude
  });
  
  Future<List<AttendanceEntity>> getAttendanceHistory(String userId);
}
