import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository;

  AttendanceProvider(this._repository);

  // Koordinat pusat pabrik (dummy Telkom University)
  // final double factoryLat = -6.974;
  // final double factoryLng = 107.631;
  
  // Koordinat dummy, kalo mau coba ubah pake lat & lng sendiri
  final double factoryLat = -6.9468545;
  final double factoryLng = 107.6526988;
  
  // Radius absensi dalam meter
  final double attendanceRadius = 500.0;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  double _currentDistance = 0.0;
  double get currentDistance => _currentDistance;

  bool _isInArea = false;
  bool get isInArea => _isInArea;
  
  int _weeklyAttendanceCount = 0;
  int get weeklyAttendanceCount => _weeklyAttendanceCount;

  List<AttendanceEntity> _history = [];
  List<AttendanceEntity> get history => _history;

  StreamSubscription<Position>? _positionStreamSubscription;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startLocationStream() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _currentDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        factoryLat,
        factoryLng,
      );
      
      _isInArea = _currentDistance <= attendanceRadius;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> calculateWeeklyStats(String userId) async {
    try {
      final historyLogs = await _repository.getAttendanceHistory(userId);
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final validLogs = historyLogs.where((log) {
        return log.type == 'check_in' && log.timestamp.isAfter(sevenDaysAgo);
      });
      
      _weeklyAttendanceCount = validLogs.length;
      notifyListeners();
    } catch (e) {
      debugPrint("Error calculating weekly stats: $e");
    }
  }

  Future<void> fetchHistory(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _history = await _repository.getAttendanceHistory(userId);
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkIn(String userId) async {
    await _submitAttendance(userId, 'check_in');
  }

  Future<void> checkOut(String userId) async {
    await _submitAttendance(userId, 'check_out');
  }

  Future<void> _submitAttendance(String userId, String type) async {
    _isLoading = true;
    notifyListeners();

    if (_currentPosition == null) {
      _isLoading = false;
      notifyListeners();
      throw 'Gagal mendapatkan lokasi. Pastikan GPS/Location service menyala dan diberi izin.';
    }

    if (!_isInArea) {
      _isLoading = false;
      notifyListeners();
      throw 'Anda berada di luar jangkauan area pabrik (> $attendanceRadius meter). Absen diblokir.';
    }

    try {
      if (type == 'check_in') {
        await _repository.checkIn(
          userId: userId,
          distance: _currentDistance,
          status: 'In Area',
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      } else {
        await _repository.checkOut(
          userId: userId,
          distance: _currentDistance,
          status: 'In Area',
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }
      
      // Update history and stats after successful check-in/out
      await fetchHistory(userId);
      await calculateWeeklyStats(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'Gagal merekam absensi: ${e.toString()}';
    }
  }
}
