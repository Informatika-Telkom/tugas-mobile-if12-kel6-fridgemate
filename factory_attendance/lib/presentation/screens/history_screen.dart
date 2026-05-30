import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/themes/app_colors.dart';
import '../providers/attendance_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<AttendanceProvider>().fetchHistory(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.deepNavy,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: attendanceProvider.isLoading && attendanceProvider.history.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.safetyOrange))
          : attendanceProvider.history.isEmpty
              ? const Center(child: Text("Belum ada riwayat absensi"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendanceProvider.history.length,
                  itemBuilder: (context, index) {
                    final log = attendanceProvider.history[index];
                    final isCheckIn = log.type == 'check_in';
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCheckIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(
                            isCheckIn ? Icons.login : Icons.logout,
                            color: isCheckIn ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          isCheckIn ? "CHECK IN" : "CHECK OUT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCheckIn ? Colors.green : Colors.red,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Jarak: ${log.distance.toStringAsFixed(1)}m | Status: ${log.status}"),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
