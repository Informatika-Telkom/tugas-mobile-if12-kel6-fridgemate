import 'package:flutter/material.dart';
import '../../data/models/attendance_model.dart';
import '../../data/services/attendance_export_service.dart';

class ExportCsvButton extends StatelessWidget {
  final List<AttendanceModel> attendances;

  const ExportCsvButton({
    Key? key,
    required this.attendances,
  }) : super(key: key);

  void _handleExport(BuildContext context) async {
    // 1. Tampilkan feedback awal kepada user bahwa proses sedang berjalan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mengekspor data ke CSV...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 2. Panggil helper service yang telah kita buat
    final service = AttendanceExportService();
    final String? filePath = await service.exportToCSV(attendances);

    // 3. Pastikan widget masih ada di tree sebelum menampilkan hasil
    if (!context.mounted) return;

    if (filePath != null) {
      // Jika berhasil, tampilkan path lokasi file dengan tema Deep Navy
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil mengekspor!\nTersimpan di:\n$filePath'),
          backgroundColor: const Color(0xFF0B1D3A), // Deep Navy
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: const Color(0xFFFF6B35), // Safety Orange
            onPressed: () {},
          ),
        ),
      );
    } else {
      // Jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengekspor data ke CSV.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleExport(context),
      icon: const Icon(Icons.download_rounded, color: Colors.white),
      label: const Text(
        'Export CSV',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35), // Safety Orange
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        shadowColor: const Color(0xFF0B1D3A).withOpacity(0.5), // Efek bayangan Deep Navy
      ),
    );
  }
}
