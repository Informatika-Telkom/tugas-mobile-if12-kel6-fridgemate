import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_entity.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> checkIn({
    required String userId,
    required double distance,
    required String status,
    required double latitude,
    required double longitude,
    String? selfieUrl,
  }) async {
    final payload = {
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'check_in',
      'distance': distance,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (selfieUrl != null && selfieUrl.trim().isNotEmpty) {
      payload['selfieUrl'] = selfieUrl;
    }

    await _firestore.collection('attendance_logs').add(payload);
  }

  @override
  Future<void> checkOut({
    required String userId,
    required double distance,
    required String status,
    required double latitude,
    required double longitude,
    String? selfieUrl,
  }) async {
    final payload = {
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'check_out',
      'distance': distance,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (selfieUrl != null && selfieUrl.trim().isNotEmpty) {
      payload['selfieUrl'] = selfieUrl;
    }

    await _firestore.collection('attendance_logs').add(payload);
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceHistory(String userId) async {
    // Ambil data hanya berdasar userId untuk menghindari kewajiban Composite Index Firestore
    final querySnapshot = await _firestore
        .collection('attendance_logs')
        .where('userId', isEqualTo: userId)
        .get();

    final logs = querySnapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();

    // Lakukan pengurutan dari yang terbaru ke terlama secara lokal
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
  }
}
