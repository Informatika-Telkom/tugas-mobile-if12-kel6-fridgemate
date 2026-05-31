import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

class AttendanceExportService {
  /// Mengambil data list AttendanceModel, mengonversinya menjadi CSV, dan menyimpan ke penyimpanan lokal.
  Future<String?> exportToCSV(List<AttendanceModel> attendances) async {
    try {
      // 1. Persiapkan Header CSV
      // Menyesuaikan dengan data yang ada di AttendanceModel
      List<List<dynamic>> rows = [
        ['ID', 'User ID (NIK)', 'Tanggal & Waktu', 'Tipe', 'Status', 'Jarak (m)', 'Latitude', 'Longitude'],
      ];

      // 2. Map data absensi ke dalam baris CSV
      for (var attendance in attendances) {
        List<dynamic> row = [
          attendance.id,
          attendance.userId,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(attendance.timestamp),
          attendance.type,
          attendance.status,
          attendance.distance.toStringAsFixed(2),
          attendance.latitude ?? '-',
          attendance.longitude ?? '-',
        ];
        rows.add(row);
      }

      // 3. Konversi Array 2D menjadi format string CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // 4. Tentukan lokasi penyimpanan lokal berdasarkan platform
      Directory? directory;
      if (Platform.isAndroid) {
        // Untuk Android, menggunakan folder penyimpanan eksternal (Documents/Download)
        directory = await getExternalStorageDirectory();
        
        // Alternatif jika ingin memaksa ke folder Download publik (membutuhkan permission storage):
        // directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        // Buat nama file unik berdasarkan timestamp
        final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final String filePath = '${directory.path}/Attendance_Export_$timestamp.csv';
        
        // 5. Simpan string CSV ke dalam file lokal
        final File file = File(filePath);
        await file.writeAsString(csvData);

        return filePath; // Mengembalikan path file jika berhasil
      }
      return null;
    } catch (e) {
      print('Error exporting CSV: $e');
      return null;
    }
  }
}
