import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/themes/app_colors.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceEntity log;

  const AttendanceDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp);
    final statusLabel = _normalizeStatus(log);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Absensi',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.deepNavy,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.type == 'check_in' ? 'CHECK IN' : 'CHECK OUT',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: $statusLabel'),
                  const SizedBox(height: 4),
                  Text('Timestamp: $dateStr'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Latitude: ${_formatCoordinate(log.latitude)}'),
                  const SizedBox(height: 4),
                  Text('Longitude: ${_formatCoordinate(log.longitude)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto Selfie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSelfiePreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfiePreview() {
    final selfieUrl = log.selfieUrl;

    if (selfieUrl == null || selfieUrl.trim().isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: Text('Foto belum tersedia')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        selfieUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 180,
            width: double.infinity,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const Text('Gagal memuat foto'),
          );
        },
      ),
    );
  }

  String _formatCoordinate(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(6);
  }

  String _normalizeStatus(AttendanceEntity log) {
    final raw = log.status.trim().toLowerCase();

    if (raw.isEmpty || raw == 'in area') {
      return 'Hadir';
    }

    if (raw.contains('telat') || raw.contains('late')) {
      return 'Telat';
    }

    if (raw.contains('izin')) {
      return 'Izin';
    }

    if (raw.contains('alpha')) {
      return 'Alpha';
    }

    return log.status;
  }
}
