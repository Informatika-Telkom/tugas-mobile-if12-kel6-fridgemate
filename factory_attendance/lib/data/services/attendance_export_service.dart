import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_model.dart';

class AttendanceExportService {
  Future<String?> exportToCsv(List<AttendanceModel> attendances) async {
    try {
      // 1. Buat StringBuffer untuk menyusun teks CSV
      StringBuffer csvBuilder = StringBuffer();

      // 2. Tambahkan Header Kolom
      csvBuilder.writeln(
        'ID,User ID,Waktu,Tipe,Status,Jarak (m),Latitude,Longitude',
      );

      // 3. Iterasi data absensi dan susun menjadi baris teks dipisahkan koma
      for (var auth in attendances) {
        String id = auth.id;
        String userId = auth.userId;
        String time = auth.timestamp.toString();
        String type = auth.type;
        String status = auth.status;
        String distance = auth.distance.toString();
        String lat = auth.latitude?.toString() ?? '';
        String lng = auth.longitude?.toString() ?? '';

        // Gabungkan dalam satu baris, gunakan tanda kutip jika teks mengandung koma
        csvBuilder.writeln(
          '"$id","$userId","$time","$type","$status","$distance","$lat","$lng"',
        );
      }

      // 4. Cari lokasi folder penyimpanan lokal (Documents/Downloads)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      // 5. Buat nama file unik berdasarkan epoch timestamp
      String epoch = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = "${directory.path}/rekap_absen_$epoch.csv";

      // 6. Tulis string ke dalam bentuk file fisik .csv
      File file = File(filePath);
      await file.writeAsString(csvBuilder.toString());

      return filePath; // Kembalikan jalur file untuk SnackBar UI
    } catch (e) {
      print("Error Manual Export CSV: $e");
      return null;
    }
  }
}
