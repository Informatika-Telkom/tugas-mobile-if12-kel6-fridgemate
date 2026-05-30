import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceModel extends AttendanceEntity {
  AttendanceModel({
    required super.id,
    required super.userId,
    required super.timestamp,
    required super.type,
    required super.status,
    required super.distance,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Document data is null");
    }
    
    // Handle pending server timestamp locally
    DateTime time;
    if (data['timestamp'] != null) {
      time = (data['timestamp'] as Timestamp).toDate();
    } else {
      time = DateTime.now();
    }

    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: time,
      type: data['type'] ?? '',
      status: data['status'] ?? '',
      distance: (data['distance'] ?? 0).toDouble(),
    );
  }
}
